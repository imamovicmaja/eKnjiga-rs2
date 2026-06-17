using System;

namespace eKnjiga.Model.Requests
{
    public class OrderReportRequest
    {
        public DateTime? DateFrom { get; set; }
        public DateTime? DateTo { get; set; }
    }
}