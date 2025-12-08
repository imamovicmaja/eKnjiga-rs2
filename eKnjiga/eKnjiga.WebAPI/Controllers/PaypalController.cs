using eKnjiga.Model.Requests;
using eKnjiga.Model.Responses;
using eKnjiga.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Http;
using System.Threading;
using System.Threading.Tasks;
using System.IO;
using System.Linq;
using System.Collections.Generic;

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

        [HttpPost("create-order")]
        public async Task<ActionResult<PaypalCreateOrderResponse>> Create([FromBody] PaypalCreateOrderRequest request, CancellationToken ct)
        {
            var result = await _paypalService.CreateOrderAsync(request, ct);
            return Ok(result);
        }

        [HttpPost("capture-order/{orderId}")]
        public async Task<ActionResult<PaypalCaptureOrderResponse>> Capture([FromRoute] string orderId, CancellationToken ct)
        {
            var result = await _paypalService.CaptureOrderAsync(orderId, ct);
            return Ok(result);
        }

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

            var ok = await _paypalService.VerifyWebhookAsync(headers, Request.Path, body, ct);
            if (!ok) return Unauthorized();

            return Ok();
        }

        [HttpGet("return")]
        public async Task<IActionResult> Return([FromQuery] string token, CancellationToken ct)
        {
            var capture = await _paypalService.CaptureOrderAsync(token, ct);
            return Ok(capture);
        }

        [HttpGet("cancel")]
        public IActionResult Cancel()
        {
            return Ok(new { status = "cancelled" });
        }
    }
}
