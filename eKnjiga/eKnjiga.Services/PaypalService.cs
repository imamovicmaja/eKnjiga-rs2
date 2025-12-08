using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using eKnjiga.Model.Requests;
using eKnjiga.Model.Responses;
using eKnjiga.Services.Database;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using System.Net.Http;

namespace eKnjiga.Services
{
    public class PaypalService : IPaypalService
    {
        private readonly IHttpClientFactory _httpFactory;
        private readonly eKnjigaDbContext _context;
        private readonly ILogger<PaypalService> _logger;

        private readonly string _clientId;
        private readonly string _clientSecret;
        private readonly string _webhookId;
        private readonly string _baseUrl;
        private readonly string _returnUrl;
        private readonly string _cancelUrl;

        public PaypalService(
            IHttpClientFactory httpFactory,
            eKnjigaDbContext context,
            IConfiguration cfg,
            ILogger<PaypalService> logger
        )
        {
            _httpFactory = httpFactory;
            _context = context;
            _logger = logger;

            _clientId     = cfg["PayPal:ClientId"]     ?? throw new ArgumentException("PayPal:ClientId nije postavljen.");
            _clientSecret = cfg["PayPal:ClientSecret"] ?? throw new ArgumentException("PayPal:ClientSecret nije postavljen.");
            _webhookId    = cfg["PayPal:WebhookId"]    ?? throw new ArgumentException("PayPal:WebhookId nije postavljen.");

            _baseUrl = cfg["PayPal:BaseUrl"];
            if (string.IsNullOrWhiteSpace(_baseUrl))
            {
                var env = Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT");
                _baseUrl = string.Equals(env, "Development", StringComparison.OrdinalIgnoreCase)
                    ? "https://api-m.sandbox.paypal.com"
                    : "https://api-m.paypal.com";
            }

            _returnUrl = cfg["PayPal:ReturnUrl"] 
                ?? throw new ArgumentException("PayPal:ReturnUrl nije postavljen.");
            _cancelUrl = cfg["PayPal:CancelUrl"] 
                ?? throw new ArgumentException("PayPal:CancelUrl nije postavljen.");
        }


        private async Task LogAsync(PaypalLog log, CancellationToken ct = default)
        {
            try
            {
                _context.PaypalLogs.Add(log);
                await _context.SaveChangesAsync(ct);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Neuspješno snimanje PayPal loga (Operation={Operation})", log.Operation);
            }
        }

        private static string JoinHeaders(IDictionary<string, string> headers) =>
            string.Join("\n", headers.Select(h => $"{h.Key}: {h.Value}"));

        private static string GetHeader(IDictionary<string, string> headers, string name)
        {
            if (headers.TryGetValue(name, out var v)) return v;
            var kv = headers.FirstOrDefault(kv => kv.Key.Equals(name, StringComparison.OrdinalIgnoreCase));
            return kv.Equals(default(KeyValuePair<string, string>)) ? string.Empty : kv.Value;
        }

        private async Task<string> GetAccessTokenAsync(CancellationToken ct)
        {
            var client = _httpFactory.CreateClient("paypal");
            var req = new System.Net.Http.HttpRequestMessage(System.Net.Http.HttpMethod.Post, $"{_baseUrl}/v1/oauth2/token");
            var auth = Convert.ToBase64String(Encoding.UTF8.GetBytes($"{_clientId}:{_clientSecret}"));
            req.Headers.Authorization = new AuthenticationHeaderValue("Basic", auth);
            req.Content = new System.Net.Http.FormUrlEncodedContent(new Dictionary<string, string> { ["grant_type"] = "client_credentials" });

            var res = await client.SendAsync(req, ct);
            var txt = await res.Content.ReadAsStringAsync(ct);

            await LogAsync(new PaypalLog
            {
                Direction = "Outbound",
                Operation = "GetAccessToken",
                Url = req.RequestUri!.ToString(),
                Method = "POST",
                HttpStatus = (int)res.StatusCode,
                ResponseBody = "{\"notice\":\"access_token redacted\"}"
            }, ct);

            if (!res.IsSuccessStatusCode)
                throw new InvalidOperationException($"PayPal token error: {res.StatusCode} {txt}");

            using var json = JsonDocument.Parse(txt);
            return json.RootElement.GetProperty("access_token").GetString()!;
        }

        public async Task<PaypalCreateOrderResponse> CreateOrderAsync(PaypalCreateOrderRequest model, CancellationToken ct = default)
        {
            var token = await GetAccessTokenAsync(ct);
            var client = _httpFactory.CreateClient("paypal");

            var payload = new
            {
                intent = "CAPTURE",
                purchase_units = new[]
                {
                    new {
                        reference_id = model.ReferenceId ?? Guid.NewGuid().ToString("N"),
                        amount = new {
                            currency_code = model.Currency,
                            value = model.Amount.ToString("0.00", System.Globalization.CultureInfo.InvariantCulture)
                        }
                    }
                },
                application_context = new {
                    shipping_preference = "NO_SHIPPING",
                    user_action = "PAY_NOW",
                    return_url = _returnUrl,
                    cancel_url = _cancelUrl
                }
            };

            var req = new System.Net.Http.HttpRequestMessage(System.Net.Http.HttpMethod.Post, $"{_baseUrl}/v2/checkout/orders");
            req.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
            var reqBody = JsonSerializer.Serialize(payload);
            req.Content = new System.Net.Http.StringContent(reqBody, Encoding.UTF8, "application/json");

            var res = await client.SendAsync(req, ct);
            var body = await res.Content.ReadAsStringAsync(ct);

            var log = new PaypalLog
            {
                Direction = "Outbound",
                Operation = "CreateOrder",
                Url = req.RequestUri!.ToString(),
                Method = "POST",
                HttpStatus = (int)res.StatusCode,
                RequestBody = reqBody,
                ResponseBody = body,
                CorrelationId = res.Headers.TryGetValues("Paypal-Debug-Id", out var v) ? v.FirstOrDefault() : null
            };
            await LogAsync(log, ct);

            res.EnsureSuccessStatusCode();

            using var doc = JsonDocument.Parse(body);
            var id = doc.RootElement.GetProperty("id").GetString()!;
            var status = doc.RootElement.GetProperty("status").GetString()!;
            var approve = doc.RootElement.GetProperty("links").EnumerateArray()
                .First(l => l.GetProperty("rel").GetString() == "approve")
                .GetProperty("href").GetString()!;

            log.OrderId = id;
            await LogAsync(log, ct);

            return new PaypalCreateOrderResponse
            {
                Id = id,
                Status = status,
                ApproveLink = approve
            };
        }

        public async Task<PaypalCaptureOrderResponse> CaptureOrderAsync(string orderId, CancellationToken ct = default)
        {
            var token = await GetAccessTokenAsync(ct);
            var client = _httpFactory.CreateClient("paypal");

            var req = new System.Net.Http.HttpRequestMessage(System.Net.Http.HttpMethod.Post, $"{_baseUrl}/v2/checkout/orders/{orderId}/capture");
            req.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);

            var res = await client.SendAsync(req, ct);
            var body = await res.Content.ReadAsStringAsync(ct);

            var log = new PaypalLog
            {
                Direction = "Outbound",
                Operation = "CaptureOrder",
                Url = req.RequestUri!.ToString(),
                Method = "POST",
                HttpStatus = (int)res.StatusCode,
                ResponseBody = body,
                OrderId = orderId,
                CorrelationId = res.Headers.TryGetValues("Paypal-Debug-Id", out var v) ? v.FirstOrDefault() : null
            };
            await LogAsync(log, ct);

            res.EnsureSuccessStatusCode();

            using var doc = JsonDocument.Parse(body);
            var status = doc.RootElement.GetProperty("status").GetString()!;
            string? captureId = null;

            try
            {
                captureId = doc.RootElement
                    .GetProperty("purchase_units")[0]
                    .GetProperty("payments")
                    .GetProperty("captures")[0]
                    .GetProperty("id").GetString();
            }
            catch { /* OK ako nema odmah capture-a */ }

            log.CaptureId = captureId;
            await LogAsync(log, ct);

            return new PaypalCaptureOrderResponse
            {
                Id = orderId,
                Status = status,
                CaptureId = captureId
            };
        }

        public async Task<bool> VerifyWebhookAsync(
            IDictionary<string, string> headers,
            string path,
            string body,
            CancellationToken ct = default
        )
        {
            await LogAsync(new PaypalLog
            {
                Direction = "Inbound",
                Operation = $"Webhook:{GetHeader(headers, "PAYPAL-EVENT-TYPE")}",
                Method = "POST",
                Url = path,
                RequestHeaders = JoinHeaders(headers),
                RequestBody = body
            }, ct);

            var token = await GetAccessTokenAsync(ct);
            var client = _httpFactory.CreateClient("paypal");

            var payload = new
            {
                auth_algo = GetHeader(headers, "PAYPAL-AUTH-ALGO"),
                cert_url = GetHeader(headers, "PAYPAL-CERT-URL"),
                transmission_id = GetHeader(headers, "PAYPAL-TRANSMISSION-ID"),
                transmission_sig = GetHeader(headers, "PAYPAL-TRANSMISSION-SIG"),
                transmission_time = GetHeader(headers, "PAYPAL-TRANSMISSION-TIME"),
                webhook_id = _webhookId,
                webhook_event = JsonSerializer.Deserialize<object>(body)
            };

            var reqMsg = new System.Net.Http.HttpRequestMessage(System.Net.Http.HttpMethod.Post, $"{_baseUrl}/v1/notifications/verify-webhook-signature");
            reqMsg.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
            var reqBody = JsonSerializer.Serialize(payload);
            reqMsg.Content = new System.Net.Http.StringContent(reqBody, Encoding.UTF8, "application/json");

            var res = await client.SendAsync(reqMsg, ct);
            var txt = await res.Content.ReadAsStringAsync(ct);

            await LogAsync(new PaypalLog
            {
                Direction = "Outbound",
                Operation = "VerifyWebhookSignature",
                Url = reqMsg.RequestUri!.ToString(),
                Method = "POST",
                HttpStatus = (int)res.StatusCode,
                RequestBody = reqBody,
                ResponseBody = txt
            }, ct);

            if (!res.IsSuccessStatusCode) return false;

            using var doc = JsonDocument.Parse(txt);
            return string.Equals(doc.RootElement.GetProperty("verification_status").GetString(), "SUCCESS", StringComparison.OrdinalIgnoreCase);
        }
    }
}
