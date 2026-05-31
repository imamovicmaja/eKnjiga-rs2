using System;
using eKnjiga.Model.Enums;

namespace eKnjiga.Model.Responses
{
    public class UserReportResponse
    {
        public int Id { get; set; }
        public string Reason { get; set; } = string.Empty;
        public UserReportStatus Status { get; set; }
        public DateTime CreatedAt { get; set; }
        public PublicUserResponse? UserReported { get; set; }
        public PublicUserResponse? ReportedByUser { get; set; }
        public DateTime? ProcessedAt { get; set; }
        public PublicUserResponse? ProcessedByUser { get; set; }
    }
}
