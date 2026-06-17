namespace eKnjiga.Model.Responses
{
    public class OrderReportResponse
    {
        public int TotalOrders { get; set; }
        public int CompletedOrders { get; set; }
        public int CancelledOrders { get; set; }
        public int PaidOrders { get; set; }

        public int PurchaseOrders { get; set; }
        public int ReservationOrders { get; set; }

        public int PdfPurchases { get; set; }
        public int HardcopyPurchases { get; set; }

        public decimal TotalRevenue { get; set; }
    }
}