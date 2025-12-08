namespace eKnjiga.Model.Responses
{
    public class OrderItemResponse
    {
        public int Id { get; set; }
        public BookResponse? Book { get; set; }
        public int Quantity { get; set; }
        public decimal UnitPrice { get; set; }
        public decimal Total => Quantity * UnitPrice;
    }
}
