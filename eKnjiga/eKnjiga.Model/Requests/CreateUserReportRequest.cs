using System.ComponentModel.DataAnnotations;

namespace eKnjiga.Model.Requests
{
    public class CreateUserReportRequest
    {
        [Required]
        [MaxLength(200)]
        public string Reason { get; set; } = string.Empty;

        [Required]
        public int UserReportedId { get; set; }
    }
}