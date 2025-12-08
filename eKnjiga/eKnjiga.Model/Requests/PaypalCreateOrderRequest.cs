namespace eKnjiga.Model.Requests
{
    public class PaypalCreateOrderRequest
    {
        public decimal Amount { get; set; }
        public string Currency { get; set; } = "BAM";
        public string? ReferenceId { get; set; }
    }
}
