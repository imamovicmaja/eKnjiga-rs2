using eKnjiga.Model.Requests;
using eKnjiga.Model.Responses;
using eKnjiga.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using System.IO;
using System.Linq;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;

namespace eKnjiga.WebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class PaypalController : ControllerBase
    {
        private readonly IPaypalService _paypalService;

        public PaypalController(IPaypalService paypalService)
        {
            _paypalService = paypalService;
        }

        [Authorize]
        [HttpPost("create-order")]
        public async Task<ActionResult<PaypalCreateOrderResponse>> Create(
            [FromBody] PaypalCreateOrderRequest request,
            CancellationToken ct)
        {
            var result = await _paypalService.CreateOrderAsync(request, ct);
            return Ok(result);
        }

        [Authorize]
        [HttpPost("capture-order/{orderId}")]
        public async Task<ActionResult<PaypalCaptureOrderResponse>> Capture(
            [FromRoute] string orderId,
            CancellationToken ct)
        {
            var result = await _paypalService.CaptureOrderAsync(orderId, ct);
            return Ok(result);
        }

        [AllowAnonymous]
        [HttpPost("webhook")]
        public async Task<IActionResult> Webhook(CancellationToken ct)
        {
            Request.EnableBuffering();

            string body;
            using (var reader = new StreamReader(Request.Body, leaveOpen: true))
            {
                body = await reader.ReadToEndAsync();
                Request.Body.Position = 0;
            }

            var headers = Request.Headers.ToDictionary(h => h.Key, h => h.Value.ToString());

            var fullUrl = $"{Request.Scheme}://{Request.Host}{Request.PathBase}{Request.Path}";
            var ok = await _paypalService.VerifyWebhookAsync(headers, fullUrl, body, ct);
            if (!ok) return Unauthorized();

            // (sljedeći korak) ovdje ćemo pozvati handler da upiše status u bazu
            // await _paypalService.HandleWebhookAsync(body, ct);

            return Ok();
        }

        [AllowAnonymous]
        [HttpGet("return")]
        public IActionResult Return([FromQuery] string? token)
        {
            if (string.IsNullOrWhiteSpace(token))
                return Redirect("eknjiga://paypal-return");

            return Redirect($"eknjiga://paypal-return?token={Uri.EscapeDataString(token)}");
        }

        [AllowAnonymous]
        [HttpGet("cancel")]
        public IActionResult Cancel()
        {
            return Redirect("eknjiga://paypal-cancel");
        }

    }
}
