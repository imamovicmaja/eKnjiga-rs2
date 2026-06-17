using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using eKnjiga.Model.Enums;
using eKnjiga.Model.Requests;
using eKnjiga.Model.Responses;
using eKnjiga.Model.Constants;
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
        private readonly INotificationService _notificationService;

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
            IHttpContextAccessor httpContextAccessor,
            INotificationService notificationService
        )
        {
            _httpFactory = httpFactory;
            _context = context;
            _logger = logger;
            _httpContextAccessor = httpContextAccessor;
            _notificationService = notificationService;

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

            return user.IsInRole(RoleNames.Admin) ||
                   user.Claims.Any(c =>
                       (c.Type == ClaimTypes.Role || c.Type == "role" || c.Type == "Role") &&
                       c.Value == RoleNames.Admin);
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

        private async Task CompletePaidOrderAsync(Order dbOrder, string? captureId, CancellationToken ct)
        {
            dbOrder.PaypalCaptureId = captureId;
            dbOrder.PaymentStatus = PaymentStatus.Paid;
            dbOrder.OrderStatus = OrderStatus.Completed;
            dbOrder.PaypalSandbox = _baseUrl.Contains("sandbox");

            if (dbOrder.Type == OrderType.Purchase)
            {
                var pdfBookIds = dbOrder.OrderItems
                    .Where(oi => oi.IsPdfPurchase)
                    .Select(oi => oi.BookId)
                    .Distinct()
                    .ToList();

                var existingBookIds = await _context.UserBooks
                    .Where(ub => ub.UserId == dbOrder.UserId && pdfBookIds.Contains(ub.BookId))
                    .Select(ub => ub.BookId)
                    .ToListAsync(ct);

                var bookIdsToAdd = pdfBookIds.Except(existingBookIds);

                foreach (var bookId in bookIdsToAdd)
                {
                    _context.UserBooks.Add(new UserBook
                    {
                        UserId = dbOrder.UserId,
                        BookId = bookId
                    });
                }
            }
        }

        public async Task<PaypalCreateOrderResponse> CreateOrderAsync(PaypalCreateOrderRequest model, CancellationToken ct = default)
        {
            EnsureUserAuthenticated();

            var order = await _context.Orders
                .FirstOrDefaultAsync(o => o.Id == model.OrderId, ct);

            if (order == null)
                throw new KeyNotFoundException($"Order {model.OrderId} ne postoji.");

            EnsureCanAccessOrder(order);

            if (order.PaymentStatus == PaymentStatus.Paid)
                throw new InvalidOperationException("Narudžba je već plaćena.");

            if (order.OrderStatus == OrderStatus.Completed)
                throw new InvalidOperationException("Završena narudžba se ne može ponovo platiti.");

            if (order.OrderStatus == OrderStatus.Cancelled)
                throw new InvalidOperationException("Otkazana narudžba se ne može platiti.");

            if (!string.IsNullOrWhiteSpace(order.PaypalOrderId) &&
                order.PaymentStatus == PaymentStatus.Pending)
            {
                throw new InvalidOperationException("Za ovu narudžbu već postoji aktivan PayPal order.");
            }

            if (order.TotalPrice != model.Amount)
                throw new InvalidOperationException($"Amount mismatch. DB={order.TotalPrice} Request={model.Amount}");

            var currency = string.IsNullOrWhiteSpace(model.Currency) ? "EUR" : model.Currency;

            if (currency != "EUR")
                throw new InvalidOperationException("Dozvoljena valuta za PayPal plaćanje je EUR.");

            var token = await GetAccessTokenAsync(ct);
            var client = _httpFactory.CreateClient("paypal");

            const decimal BAM_PER_EUR = 1.95583m;
            var amountEur = Math.Round(order.TotalPrice / BAM_PER_EUR, 2, MidpointRounding.AwayFromZero);
            var amountStr = amountEur.ToString("0.00", System.Globalization.CultureInfo.InvariantCulture);

            var payload = new
            {
                intent = "CAPTURE",
                purchase_units = new[]
                {
            new
            {
                reference_id = order.Id.ToString(),
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
            EnsureUserAuthenticated();

            var dbOrder = await _context.Orders
                .Include(o => o.OrderItems)
                .FirstOrDefaultAsync(o => o.PaypalOrderId == orderId, ct);

            if (dbOrder == null)
                throw new KeyNotFoundException("Order not found.");

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

            if (dbOrder.PaymentStatus == PaymentStatus.Paid)
                throw new InvalidOperationException("Narudžba je već plaćena.");

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
            var root = capDoc.RootElement;

            var status = root.GetProperty("status").GetString();

            if (status != "COMPLETED")
                throw new InvalidOperationException($"PayPal plaćanje nije završeno. Status: {status}");

            var capture = root
                .GetProperty("purchase_units")[0]
                .GetProperty("payments")
                .GetProperty("captures")[0];

            var captureId = capture.GetProperty("id").GetString();

            var captureStatus = capture.GetProperty("status").GetString();
            if (captureStatus != "COMPLETED")
                throw new InvalidOperationException($"PayPal capture nije završen. Status: {captureStatus}");

            var amountElement = capture.GetProperty("amount");
            var currency = amountElement.GetProperty("currency_code").GetString();
            var valueString = amountElement.GetProperty("value").GetString();

            if (currency != "EUR")
                throw new InvalidOperationException($"Neispravna valuta. PayPal={currency}, očekivano=EUR.");

            if (!decimal.TryParse(
                    valueString,
                    System.Globalization.NumberStyles.Number,
                    System.Globalization.CultureInfo.InvariantCulture,
                    out var capturedAmountEur))
            {
                throw new InvalidOperationException("PayPal iznos nije validan.");
            }

            const decimal BAM_PER_EUR = 1.95583m;
            var expectedAmountEur = Math.Round(dbOrder.TotalPrice / BAM_PER_EUR, 2, MidpointRounding.AwayFromZero);

            if (capturedAmountEur != expectedAmountEur)
            {
                throw new InvalidOperationException(
                    $"Iznos se ne poklapa. PayPal={capturedAmountEur} EUR, očekivano={expectedAmountEur} EUR."
                );
            }

            using var transaction = await _context.Database.BeginTransactionAsync(ct);

            await CompletePaidOrderAsync(dbOrder, captureId, ct);

            await _context.SaveChangesAsync(ct);
            await transaction.CommitAsync(ct);

            await _notificationService.CreateAsync(
                dbOrder.UserId,
                "Plaćanje",
                "Vaše plaćanje je uspješno evidentirano."
            );

            return new PaypalCaptureOrderResponse
            {
                Id = orderId,
                Status = status!,
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
            using var doc = JsonDocument.Parse(body);
            var root = doc.RootElement;

            if (!root.TryGetProperty("event_type", out var eventTypeElement))
                return;

            var eventType = eventTypeElement.GetString();

            if (eventType != "PAYMENT.CAPTURE.COMPLETED")
            {
                _logger.LogInformation("PayPal webhook ignored. EventType={EventType}", eventType);
                return;
            }

            var resource = root.GetProperty("resource");

            var captureId = resource.GetProperty("id").GetString();
            var captureStatus = resource.GetProperty("status").GetString();

            if (captureStatus != "COMPLETED")
                return;

            var amountElement = resource.GetProperty("amount");
            var currency = amountElement.GetProperty("currency_code").GetString();
            var valueString = amountElement.GetProperty("value").GetString();

            if (currency != "EUR")
                throw new InvalidOperationException($"Neispravna valuta u webhooku. PayPal={currency}, očekivano=EUR.");

            if (!decimal.TryParse(
                    valueString,
                    System.Globalization.NumberStyles.Number,
                    System.Globalization.CultureInfo.InvariantCulture,
                    out var capturedAmountEur))
            {
                throw new InvalidOperationException("PayPal webhook iznos nije validan.");
            }

            string? paypalOrderId = null;

            if (resource.TryGetProperty("supplementary_data", out var supplementaryData) &&
                supplementaryData.TryGetProperty("related_ids", out var relatedIds) &&
                relatedIds.TryGetProperty("order_id", out var orderIdElement))
            {
                paypalOrderId = orderIdElement.GetString();
            }

            if (string.IsNullOrWhiteSpace(paypalOrderId))
            {
                _logger.LogWarning("PayPal webhook nema order_id. CaptureId={CaptureId}", captureId);
                return;
            }

            var dbOrder = await _context.Orders
                .Include(o => o.OrderItems)
                .FirstOrDefaultAsync(o => o.PaypalOrderId == paypalOrderId, ct);

            if (dbOrder == null)
            {
                _logger.LogWarning("PayPal webhook order nije pronađen. PaypalOrderId={PaypalOrderId}", paypalOrderId);
                return;
            }

            if (!string.IsNullOrWhiteSpace(dbOrder.PaypalCaptureId))
            {
                _logger.LogInformation("PayPal webhook već obrađen. CaptureId={CaptureId}", dbOrder.PaypalCaptureId);
                return;
            }

            const decimal BAM_PER_EUR = 1.95583m;
            var expectedAmountEur = Math.Round(dbOrder.TotalPrice / BAM_PER_EUR, 2, MidpointRounding.AwayFromZero);

            if (capturedAmountEur != expectedAmountEur)
            {
                throw new InvalidOperationException(
                    $"Webhook iznos se ne poklapa. PayPal={capturedAmountEur} EUR, očekivano={expectedAmountEur} EUR."
                );
            }

            using var transaction = await _context.Database.BeginTransactionAsync(ct);

            await CompletePaidOrderAsync(dbOrder, captureId, ct);

            await _context.SaveChangesAsync(ct);
            await transaction.CommitAsync(ct);

            await _notificationService.CreateAsync(
                dbOrder.UserId,
                "Plaćanje",
                "Vaše plaćanje je uspješno evidentirano."
            );
        }
    }
}