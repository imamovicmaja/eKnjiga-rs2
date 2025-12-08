namespace eKnjiga.Model.Responses
{
    public class PaypalCaptureOrderResponse
    {
        public string Id { get; set; } = string.Empty;
        public string Status { get; set; } = string.Empty;
        public string? CaptureId { get; set; }
    }
}
