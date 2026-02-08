using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using eKnjiga.Model.Requests;
using eKnjiga.Model.Responses;

namespace eKnjiga.Services
{
    public interface IPaypalService
    {
        Task<PaypalCreateOrderResponse> CreateOrderAsync(
            PaypalCreateOrderRequest request,
            CancellationToken ct = default
        );

        Task<PaypalCaptureOrderResponse> CaptureOrderAsync(
            string orderId,
            CancellationToken ct = default
        );

        Task<bool> VerifyWebhookAsync(
            IDictionary<string, string> headers,
            string webhookUrl,
            string body,
            CancellationToken ct = default
        );
        
        Task HandleWebhookAsync(
            string body,
            CancellationToken ct = default
        );
    }
}
