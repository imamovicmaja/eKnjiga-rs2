using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using eKnjiga.Model.Enums;

namespace eKnjiga.Model.Requests
{
    public class OrderUpsertRequest
    {
        [Required]
        public DateTime OrderDate { get; set; } = DateTime.UtcNow;

        [Required]
        public decimal TotalPrice { get; set; }

        [Required]
        public OrderStatus OrderStatus { get; set; } = OrderStatus.Pending;

        [Required]
        public PaymentStatus PaymentStatus { get; set; } = PaymentStatus.Unpaid;

        [Required]
        public OrderType Type { get; set; } = OrderType.Purchase;

        [Required]
        public int UserId { get; set; }

        [Required]
        public List<OrderItemInsertRequest> OrderItems { get; set; } = new List<OrderItemInsertRequest>();
    }
}
