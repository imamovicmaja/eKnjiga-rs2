using System;
using System.Collections.Generic;
using eKnjiga.Model.Enums;

namespace eKnjiga.Model.Responses
{
    public class OrderResponse
    {
        public int Id { get; set; }
        public DateTime OrderDate { get; set; }
        public decimal TotalPrice { get; set; }
        public OrderStatus OrderStatus { get; set; }
        public PaymentStatus PaymentStatus { get; set; }
        public OrderType Type { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? ExpiresAt { get; set; }
        public UserResponse? User { get; set; }
        public string? StatusChangedByName { get; set; }
        public DateTime? StatusChangedAt { get; set; }
        public string? CancellationReason { get; set; }
        public List<OrderItemResponse> OrderItems { get; set; } = new List<OrderItemResponse>();
    }
}
