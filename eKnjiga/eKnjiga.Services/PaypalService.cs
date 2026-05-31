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
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using System.Security.Claims;

namespace eKnjiga.Services
{
    public class PaypalService : IPaypalService
    {
        private readonly IHttpClientFactory _httpFactory;
        private readonly eKnjigaDbContext _context;
        private readonly ILogger<PaypalService> _logger;
        private readonly IHttpContextAccessor _httpContextAccessor;

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
            ILogger<PaypalService> logger,
            IHttpContextAccessor httpContextAccessor
        )
        {
            _httpFactory = httpFactory;
            _context = context;
            _logger = logger;
            _httpContextAccessor = httpContextAccessor;

            _clientId = cfg["PayPal:ClientId"] ?? throw new ArgumentException("PayPal:ClientId nije postavljen.");
            _clientSecret = cfg["PayPal:ClientSecret"] ?? throw new ArgumentException("PayPal:ClientSecret nije postavljen.");
            _webhookId = cfg["PayPal:WebhookId"] ?? throw new ArgumentException("PayPal:WebhookId nije postavljen.");
            _baseUrl = cfg["PayPal:BaseUrl"] ?? throw new ArgumentException("PayPal:BaseUrl nije postavljen.");
            _returnUrl = cfg["PayPal:ReturnUrl"] ?? throw new ArgumentException("PayPal:ReturnUrl nije postavljen.");
            _cancelUrl = cfg["PayPal:CancelUrl"] ?? throw new ArgumentException("PayPal:CancelUrl nije postavljen.");
        }

        private int? GetCurrentUserId()
        {
            var user = _httpContextAccessor.HttpContext?.User;

            var userIdClaim =
                user?.FindFirst(ClaimTypes.NameIdentifier)?.Value ??
                user?.FindFirst("UserId")?.Value ??
                user?.FindFirst("Id")?.Value;

            if (int.TryParse(userIdClaim, out var userId))
                return userId;

            return null;
        }

        private bool IsAdmin()
        {
            var user = _httpContextAccessor.HttpContext?.User;

            if (user == null)
                return false;

            return user.IsInRole("Admin") ||
                   user.Claims.Any(c =>
                       (c.Type == ClaimTypes.Role || c.Type == "role" || c.Type == "Role") &&
                       c.Value == "Admin");
        }

        private void EnsureUserAuthenticated()
        {
            if (!GetCurrentUserId().HasValue)
                throw new UnauthorizedAccessException("User is not authenticated.");
        }

        private void EnsureCanAccessOrder(Order order)
        {
            if (IsAdmin())
                return;

            var currentUserId = GetCurrentUserId();

            if (!currentUserId.HasValue)
                throw new UnauthorizedAccessException("User is not authenticated.");

            if (order.UserId != currentUserId.Value)
                throw new UnauthorizedAccessException("You are not allowed to access this order.");
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
            EnsureUserAuthenticated();

            var order = await _context.Orders.FirstOrDefaultAsync(o => o.Id == model.OrderId, ct);
            if (order == null)
                throw new KeyNotFoundException($"Order {model.OrderId} ne postoji.");

            EnsureCanAccessOrder(order);

            if (order.TotalPrice != model.Amount)
                throw new InvalidOperationException($"Amount mismatch. DB={order.TotalPrice} Request={model.Amount}");

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
                    value = amountStr
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
            req.Content = new StringContent(JsonSerializer.Serialize(payload), Encoding.UTF8, "application/json");

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

            order.PaypalOrderId = paypalOrderId;
            order.PaymentStatus = PaymentStatus.Pending;
            order.PaypalSandbox = _baseUrl.Contains("sandbox");

            await _context.SaveChangesAsync(ct);

            return new PaypalCreateOrderResponse
            {
                Id = paypalOrderId,
                Status = status,
                ApproveLink = approve
            };
        }

        public async Task<PaypalCaptureOrderResponse> CaptureOrderAsync(string orderId, CancellationToken ct = default)
        {
            var dbOrder = await _context.Orders
                .FirstOrDefaultAsync(o => o.PaypalOrderId == orderId, ct);

            if (dbOrder == null)
                throw new KeyNotFoundException("Order not found.");

            EnsureUserAuthenticated();
            EnsureCanAccessOrder(dbOrder);

            if (!string.IsNullOrWhiteSpace(dbOrder.PaypalCaptureId))
            {
                return new PaypalCaptureOrderResponse
                {
                    Id = orderId,
                    Status = "ALREADY_CAPTURED",
                    CaptureId = dbOrder.PaypalCaptureId
                };
            }

            var token = await GetAccessTokenAsync(ct);
            var client = _httpFactory.CreateClient("paypal");

            var captureReq = new HttpRequestMessage(
                HttpMethod.Post,
                $"{_baseUrl}/v2/checkout/orders/{orderId}/capture");

            captureReq.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
            captureReq.Content = new StringContent("{}", Encoding.UTF8, "application/json");

            var captureRes = await client.SendAsync(captureReq, ct);
            var captureBody = await captureRes.Content.ReadAsStringAsync(ct);

            if (!captureRes.IsSuccessStatusCode)
                throw new InvalidOperationException($"PayPal capture error {(int)captureRes.StatusCode}: {captureBody}");

            using var capDoc = JsonDocument.Parse(captureBody);

            var status = capDoc.RootElement.GetProperty("status").GetString()!;
            var captureId = capDoc.RootElement
                .GetProperty("purchase_units")[0]
                .GetProperty("payments")
                .GetProperty("captures")[0]
                .GetProperty("id")
                .GetString();

            dbOrder.PaypalCaptureId = captureId;
            dbOrder.PaymentStatus = PaymentStatus.Paid;
            dbOrder.PaypalSandbox = _baseUrl.Contains("sandbox");

            await _context.SaveChangesAsync(ct);

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
            CancellationToken ct = default)
        {
            var token = await GetAccessTokenAsync(ct);
            var client = _httpFactory.CreateClient("paypal");

            var payload = new
            {
                auth_algo = headers["PAYPAL-AUTH-ALGO"],
                cert_url = headers["PAYPAL-CERT-URL"],
                transmission_id = headers["PAYPAL-TRANSMISSION-ID"],
                transmission_sig = headers["PAYPAL-TRANSMISSION-SIG"],
                transmission_time = headers["PAYPAL-TRANSMISSION-TIME"],
                webhook_id = _webhookId,
                webhook_event = JsonSerializer.Deserialize<object>(body)
            };

            var req = new HttpRequestMessage(HttpMethod.Post, $"{_baseUrl}/v1/notifications/verify-webhook-signature");
            req.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
            req.Content = new StringContent(JsonSerializer.Serialize(payload), Encoding.UTF8, "application/json");

            var res = await client.SendAsync(req, ct);
            var txt = await res.Content.ReadAsStringAsync(ct);

            if (!res.IsSuccessStatusCode)
                return false;

            using var doc = JsonDocument.Parse(txt);
            return doc.RootElement.GetProperty("verification_status").GetString() == "SUCCESS";
        }

        public async Task HandleWebhookAsync(string body, CancellationToken ct = default)
        {
            _logger.LogInformation("Webhook received: {Body}", body);
            await Task.CompletedTask;
        }
    }
}