using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using eKnjiga.Model.Enums;

namespace eKnjiga.Model.Requests
{
    public class OrderUpsertRequest
    {
        [Required]
        public OrderType Type { get; set; } = OrderType.Purchase;

        [Required]
        [MinLength(1, ErrorMessage = "Narudžba mora sadržavati barem jednu knjigu.")]
        public List<OrderItemInsertRequest> OrderItems { get; set; } = new();
    }
}