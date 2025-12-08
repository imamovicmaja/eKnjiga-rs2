using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace eKnjiga.Services.Database
{
    public class OrderItem
    {
        public int Id { get; set; } 
        
        public int OrderId { get; set; }
        [ForeignKey("OrderId")]
        public Order Order { get; set; } = null!;

        public int BookId { get; set; }
        [ForeignKey("BookId")]
        public Book Book { get; set; } = null!;

        public int Quantity { get; set; }

        public decimal UnitPrice { get; set; }

        public decimal Total => Quantity * UnitPrice;
    }
} 