using System.ComponentModel.DataAnnotations;

namespace eKnjiga.Model.Requests
{
    public class OrderItemInsertRequest
    {
        [Required]
        public int BookId { get; set; }

        [Range(1, int.MaxValue, ErrorMessage = "Količina mora biti najmanje 1.")]
        public int Quantity { get; set; }

        [Required]
        public bool IsPdfPurchase { get; set; }
    }
}