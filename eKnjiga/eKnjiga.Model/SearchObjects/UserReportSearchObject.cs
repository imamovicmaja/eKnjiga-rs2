using System;
using System.Collections.Generic;
using System.Text;
using eKnjiga.Model.Enums;

namespace eKnjiga.Model.SearchObjects
{
    public class UserReportSearchObject : BaseSearchObject
    {
        public string? Reason { get; set; } = string.Empty;
        public UserReportStatus? Status { get; set; }
        public int? UserReportedId { get; set; }
        public int? ReportedByUserId { get; set; }
    }
}
