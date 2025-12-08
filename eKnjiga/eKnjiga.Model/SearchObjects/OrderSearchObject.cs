using System;
using System.Collections.Generic;
using System.Text;
using eKnjiga.Model.Enums;

namespace eKnjiga.Model.SearchObjects
{
    public class OrderSearchObject : BaseSearchObject
    {
        public int? UserId { get; set; }
        public decimal? TotalPrice { get; set; }
        public OrderStatus? OrderStatus { get; set; } 
        public PaymentStatus? PaymentStatus { get; set; }
        public OrderType? Type { get; set; }
        public string? OrderBy { get; set; }
        public bool? IsDescending { get; set; }
    }
}
