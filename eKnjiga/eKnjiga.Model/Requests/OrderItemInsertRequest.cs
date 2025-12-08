using System.ComponentModel.DataAnnotations;

namespace eKnjiga.Model.Requests
{
    public class OrderItemInsertRequest
    {
        [Required]
        public int BookId { get; set; }

        [Required]
        public int Quantity { get; set; }

        [Required]
        public decimal UnitPrice { get; set; }
    }
}
