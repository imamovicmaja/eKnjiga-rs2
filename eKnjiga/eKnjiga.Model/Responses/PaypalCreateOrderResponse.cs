namespace eKnjiga.Model.Responses
{
    public class PaypalCreateOrderResponse
    {
        public string Id { get; set; } = string.Empty;
        public string Status { get; set; } = string.Empty;
        public string ApproveLink { get; set; } = string.Empty;
    }
}
