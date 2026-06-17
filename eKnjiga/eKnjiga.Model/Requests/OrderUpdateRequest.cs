using eKnjiga.Model.Enums;
using System.ComponentModel.DataAnnotations;

namespace eKnjiga.Model.Requests
{
    public class OrderUpdateRequest
    {
        public OrderStatus OrderStatus { get; set; }
        public PaymentStatus PaymentStatus { get; set; }
        [MaxLength(300)]
        public string? Reason { get; set; }
    }
}
