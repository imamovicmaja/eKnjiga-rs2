using System.ComponentModel.DataAnnotations;

namespace eKnjiga.Model.Requests
{
    public class ReviewUpsertRequest
    {
        [Required]
        public double Rating { get; set; }

        [Required]
        public int BookId { get; set; }

        [Required]
        public int UserId { get; set; }
    }
}
