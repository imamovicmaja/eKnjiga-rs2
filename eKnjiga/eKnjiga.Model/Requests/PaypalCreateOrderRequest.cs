namespace eKnjiga.Model.Requests
{
    public class PaypalCreateOrderRequest
    {
        public int OrderId { get; set; }
        public decimal Amount { get; set; }
        public string Currency { get; set; } = "EUR";
        public string? ReferenceId { get; set; }
    }
}
