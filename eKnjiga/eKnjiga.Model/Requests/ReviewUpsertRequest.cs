using System.ComponentModel.DataAnnotations;

namespace eKnjiga.Model.Requests
{
    public class ReviewUpsertRequest
    {
        [Required]
        [Range(1, 5)]
        public double Rating { get; set; }

        [Required]
        public int BookId { get; set; }

    }
}
