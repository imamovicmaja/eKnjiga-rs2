using System.ComponentModel.DataAnnotations;
using eKnjiga.Model.Enums;

namespace eKnjiga.Model.Requests
{
    public class UserReportUpsertRequest
    {
        [Required]
        [MaxLength(200)]
        public string Reason { get; set; } = string.Empty;

        [Required]
        public UserReportStatus Status { get; set; } = UserReportStatus.Pending;

        [Required]
        public int UserReportedId { get; set; }

        [Required]
        public int ReportedByUserId { get; set; }

        public int? ProcessedByUserId { get; set; }
    }
}
