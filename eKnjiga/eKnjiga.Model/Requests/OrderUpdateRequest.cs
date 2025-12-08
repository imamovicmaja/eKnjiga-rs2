using eKnjiga.Model.Enums;

namespace eKnjiga.Model.Requests
{
    public class OrderUpdateRequest
    {
        public OrderStatus OrderStatus { get; set; }
        public PaymentStatus PaymentStatus { get; set; }
    }
}
