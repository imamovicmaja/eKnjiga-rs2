using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using eKnjiga.Model.Enums;

namespace eKnjiga.Services.Database
{
    public class Order
    {
        [Key]
        public int Id { get; set; }

        public DateTime OrderDate { get; set; } = DateTime.UtcNow;

        public decimal TotalPrice { get; set; }

        public OrderStatus OrderStatus { get; set; } = OrderStatus.Pending;

        public PaymentStatus PaymentStatus { get; set; } = PaymentStatus.Unpaid;

        public OrderType Type { get; set; } = OrderType.Purchase;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        [MaxLength(128)]
        public string? PaypalOrderId { get; set; }

        [MaxLength(128)]
        public string? PaypalCaptureId { get; set; }

        public bool? PaypalSandbox { get; set; }

        public int UserId { get; set; }

        [ForeignKey("UserId")]
        public User User { get; set; } = null!;

        public ICollection<OrderItem> OrderItems { get; set; } = new List<OrderItem>();
    }
}