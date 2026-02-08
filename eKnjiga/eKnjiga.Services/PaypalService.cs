using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using eKnjiga.Model.Enums;
using eKnjiga.Model.Requests;
using eKnjiga.Model.Responses;
using eKnjiga.Services.Database;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

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

            _clientId = cfg["PayPal:ClientId"] ?? throw new ArgumentException("PayPal:ClientId nije postavljen.");
            _clientSecret = cfg["PayPal:ClientSecret"] ?? throw new ArgumentException("PayPal:ClientSecret nije postavljen.");
            _webhookId = cfg["PayPal:WebhookId"] ?? throw new ArgumentException("PayPal:WebhookId nije postavljen.");

            _baseUrl = cfg["PayPal:BaseUrl"];
            if (string.IsNullOrWhiteSpace(_baseUrl))
            {
                var env = Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT");
                _baseUrl = string.Equals(env, "Development", StringComparison.OrdinalIgnoreCase)
                    ? "https://api-m.sandbox.paypal.com"
                    : "https://api-m.paypal.com";
            }

            _returnUrl = cfg["PayPal:ReturnUrl"] ?? throw new ArgumentException("PayPal:ReturnUrl nije postavljen.");
            _cancelUrl = cfg["PayPal:CancelUrl"] ?? throw new ArgumentException("PayPal:CancelUrl nije postavljen.");
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
            var req = new HttpRequestMessage(HttpMethod.Post, $"{_baseUrl}/v1/oauth2/token");

            var auth = Convert.ToBase64String(Encoding.UTF8.GetBytes($"{_clientId}:{_clientSecret}"));
            req.Headers.Authorization = new AuthenticationHeaderValue("Basic", auth);
            req.Content = new FormUrlEncodedContent(new Dictionary<string, string>
            {
                ["grant_type"] = "client_credentials"
            });

            var res = await client.SendAsync(req, ct);
            var txt = await res.Content.ReadAsStringAsync(ct);

            if (!res.IsSuccessStatusCode)
                throw new InvalidOperationException($"PayPal token error {(int)res.StatusCode}: {txt}");

            using var json = JsonDocument.Parse(txt);
            return json.RootElement.GetProperty("access_token").GetString()!;
        }

        public async Task<PaypalCreateOrderResponse> CreateOrderAsync(PaypalCreateOrderRequest model, CancellationToken ct = default)
        {
            // 1) Ucitaj order iz baze
            var order = await _context.Orders.FirstOrDefaultAsync(o => o.Id == model.OrderId, ct);
            if (order == null)
                throw new InvalidOperationException($"Order {model.OrderId} ne postoji.");

            // 2) Sigurnosna provjera iznosa
            if (order.TotalPrice != model.Amount)
                throw new InvalidOperationException($"Amount mismatch. DB={order.TotalPrice} Request={model.Amount}");

            // 3) Currency
            var currency = string.IsNullOrWhiteSpace(model.Currency) ? "EUR" : model.Currency;

            var token = await GetAccessTokenAsync(ct);
            var client = _httpFactory.CreateClient("paypal");

            const decimal BAM_PER_EUR = 1.95583m;
            var amountEur = Math.Round((decimal)model.Amount / BAM_PER_EUR, 2, MidpointRounding.AwayFromZero);

            var amountStr = amountEur.ToString("0.00", System.Globalization.CultureInfo.InvariantCulture);

            var payload = new
            {
                intent = "CAPTURE",
                purchase_units = new[]
                {
                    new
                    {
                        reference_id = model.ReferenceId ?? order.Id.ToString(),
                        description = $"eKnjiga order #{order.Id}",

                        amount = new
                        {
                            currency_code = currency,
                            value = amountStr,
                            breakdown = new
                            {
                                item_total = new { currency_code = currency, value = amountStr }
                            }
                        },

                        items = new[]
                        {
                            new
                            {
                                name = "eKnjiga purchase",
                                description = $"Order #{order.Id}",
                                quantity = "1",
                                category = "DIGITAL_GOODS",
                                unit_amount = new { currency_code = currency, value = amountStr }
                            }
                        }
                    }
                },
                application_context = new
                {
                    shipping_preference = "NO_SHIPPING",
                    user_action = "PAY_NOW",
                    return_url = _returnUrl,
                    cancel_url = _cancelUrl
                }
            };

            var req = new HttpRequestMessage(HttpMethod.Post, $"{_baseUrl}/v2/checkout/orders");
            req.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);

            var reqBody = JsonSerializer.Serialize(payload);
            req.Content = new StringContent(reqBody, Encoding.UTF8, "application/json");

            var res = await client.SendAsync(req, ct);
            var body = await res.Content.ReadAsStringAsync(ct);

            if (!res.IsSuccessStatusCode)
                throw new InvalidOperationException($"PayPal create-order error {(int)res.StatusCode}: {body}");

            using var doc = JsonDocument.Parse(body);
            var paypalOrderId = doc.RootElement.GetProperty("id").GetString()!;
            var status = doc.RootElement.GetProperty("status").GetString()!;
            var approve = doc.RootElement.GetProperty("links").EnumerateArray()
                .First(l => l.GetProperty("rel").GetString() == "approve")
                .GetProperty("href").GetString()!;

            // 5) Upisi u DB
            order.PaypalOrderId = paypalOrderId;
            order.PaypalSandbox = _baseUrl.Contains("sandbox", StringComparison.OrdinalIgnoreCase);
            order.PaymentStatus = PaymentStatus.Pending;

            await _context.SaveChangesAsync(ct);

            return new PaypalCreateOrderResponse
            {
                Id = paypalOrderId,
                Status = status,
                ApproveLink = approve
            };
        }

        public async Task<PaypalCaptureOrderResponse> CaptureOrderAsync(
    string orderId,
    CancellationToken ct = default)
{
    _logger.LogInformation("=== PAYPAL CAPTURE START === orderId={OrderId}", orderId);

    // 0) Provjera u bazi (idempotency)
    var dbOrder = await _context.Orders
        .FirstOrDefaultAsync(o => o.PaypalOrderId == orderId, ct);

    if (dbOrder == null)
    {
        _logger.LogWarning("DB ORDER NOT FOUND for paypalOrderId={OrderId}", orderId);
    }
    else
    {
        _logger.LogInformation(
            "DB ORDER FOUND. Status={PaymentStatus}, CaptureId={CaptureId}",
            dbOrder.PaymentStatus,
            dbOrder.PaypalCaptureId
        );
    }

    if (dbOrder != null && !string.IsNullOrWhiteSpace(dbOrder.PaypalCaptureId))
    {
        _logger.LogWarning(
            "ORDER ALREADY CAPTURED. Returning existing captureId={CaptureId}",
            dbOrder.PaypalCaptureId
        );

        return new PaypalCaptureOrderResponse
        {
            Id = orderId,
            Status = "ALREADY_CAPTURED",
            CaptureId = dbOrder.PaypalCaptureId
        };
    }

    // 1) Access token
    var token = await GetAccessTokenAsync(ct);
    _logger.LogInformation("Access token acquired");

    var client = _httpFactory.CreateClient("paypal");

    // 2) GET ORDER (status)
    var getReq = new HttpRequestMessage(
        HttpMethod.Get,
        $"{_baseUrl}/v2/checkout/orders/{orderId}"
    );
    getReq.Headers.Authorization =
        new AuthenticationHeaderValue("Bearer", token);

    _logger.LogInformation("GET ORDER -> {Url}", getReq.RequestUri);

    var getRes = await client.SendAsync(getReq, ct);
    var getBody = await getRes.Content.ReadAsStringAsync(ct);

    _logger.LogInformation(
        "GET ORDER RESPONSE status={StatusCode}, body={Body}",
        (int)getRes.StatusCode,
        getBody
    );

    if (!getRes.IsSuccessStatusCode)
    {
        _logger.LogError(
            "GET ORDER FAILED status={StatusCode}, body={Body}",
            (int)getRes.StatusCode,
            getBody
        );

        throw new InvalidOperationException(
            $"PayPal get-order error {(int)getRes.StatusCode}: {getBody}");
    }

    using var getDoc = JsonDocument.Parse(getBody);
    var orderStatus = getDoc.RootElement.GetProperty("status").GetString();

    _logger.LogInformation("Order status before capture = {OrderStatus}", orderStatus);

    if (!string.Equals(orderStatus, "APPROVED", StringComparison.OrdinalIgnoreCase))
    {
        _logger.LogError(
            "ORDER NOT APPROVED. status={OrderStatus}. Capture aborted.",
            orderStatus
        );

        throw new InvalidOperationException(
            $"Order nije APPROVED (status={orderStatus}). Capture se ne izvršava.");
    }

    // 3) CAPTURE
    var captureReq = new HttpRequestMessage(
        HttpMethod.Post,
        $"{_baseUrl}/v2/checkout/orders/{orderId}/capture"
    );
    captureReq.Headers.Authorization =
        new AuthenticationHeaderValue("Bearer", token);
    captureReq.Headers.Accept.Add(
        new MediaTypeWithQualityHeaderValue("application/json"));
    captureReq.Content =
        new StringContent("{}", Encoding.UTF8, "application/json");

    _logger.LogInformation("CAPTURE ORDER -> {Url}", captureReq.RequestUri);

    var captureRes = await client.SendAsync(captureReq, ct);
    var captureBody = await captureRes.Content.ReadAsStringAsync(ct);

    _logger.LogInformation(
        "CAPTURE RESPONSE status={StatusCode}, body={Body}",
        (int)captureRes.StatusCode,
        captureBody
    );

    if (!captureRes.IsSuccessStatusCode)
    {
        _logger.LogError(
            "CAPTURE FAILED status={StatusCode}, body={Body}",
            (int)captureRes.StatusCode,
            captureBody
        );

        throw new InvalidOperationException(
            $"PayPal capture error {(int)captureRes.StatusCode}: {captureBody}");
    }

    // 4) Parsiranje capture ID-a
    using var capDoc = JsonDocument.Parse(captureBody);
    var status = capDoc.RootElement.GetProperty("status").GetString()!;
    string? captureId = null;

    try
    {
        captureId = capDoc.RootElement
            .GetProperty("purchase_units")[0]
            .GetProperty("payments")
            .GetProperty("captures")[0]
            .GetProperty("id")
            .GetString();
    }
    catch
    {
        _logger.LogWarning("CaptureId not found in PayPal response");
    }

    _logger.LogInformation("Parsed captureId={CaptureId}", captureId);

    // 5) Update baze
    if (dbOrder != null)
    {
        dbOrder.PaypalCaptureId = captureId;
        dbOrder.PaymentStatus = PaymentStatus.Paid;
        dbOrder.OrderStatus = OrderStatus.Completed;
        await _context.SaveChangesAsync(ct);

        _logger.LogInformation("DB UPDATED: Order marked as PAID");
    }

    _logger.LogInformation("=== PAYPAL CAPTURE SUCCESS ===");

    return new PaypalCaptureOrderResponse
    {
        Id = orderId,
        Status = status,
        CaptureId = captureId
    };
}

        public async Task<bool> VerifyWebhookAsync(
            IDictionary<string, string> headers,
            string webhookUrl,
            string body,
            CancellationToken ct = default
        )
        {
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

            var reqMsg = new HttpRequestMessage(HttpMethod.Post, $"{_baseUrl}/v1/notifications/verify-webhook-signature");
            reqMsg.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);

            var reqBody = JsonSerializer.Serialize(payload);
            reqMsg.Content = new StringContent(reqBody, Encoding.UTF8, "application/json");

            var res = await client.SendAsync(reqMsg, ct);
            var txt = await res.Content.ReadAsStringAsync(ct);

            if (!res.IsSuccessStatusCode) return false;

            using var doc = JsonDocument.Parse(txt);
            return string.Equals(
                doc.RootElement.GetProperty("verification_status").GetString(),
                "SUCCESS",
                StringComparison.OrdinalIgnoreCase
            );
        }

        public async Task HandleWebhookAsync(string body, CancellationToken ct = default)
        {
            using var doc = JsonDocument.Parse(body);

            var eventType = doc.RootElement.TryGetProperty("event_type", out var et)
                ? et.GetString()
                : null;

            string? orderId = null;
            if (doc.RootElement.TryGetProperty("resource", out var res) &&
                res.ValueKind == JsonValueKind.Object &&
                res.TryGetProperty("id", out var rid))
            {
                orderId = rid.GetString();
            }

            if (string.IsNullOrWhiteSpace(eventType))
                return;

            _logger.LogInformation("PayPal webhook handled. event_type={EventType}, orderId={OrderId}", eventType, orderId);
        }
    }
}
