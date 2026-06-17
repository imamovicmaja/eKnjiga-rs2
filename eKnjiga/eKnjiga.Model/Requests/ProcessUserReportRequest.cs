using System.ComponentModel.DataAnnotations;
using eKnjiga.Model.Enums;

namespace eKnjiga.Model.Requests
{
    public class ProcessUserReportRequest
    {
        [Required]
        public UserReportStatus Status { get; set; }
    }
}