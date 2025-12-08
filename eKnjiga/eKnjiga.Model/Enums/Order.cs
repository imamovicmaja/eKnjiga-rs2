namespace eKnjiga.Model.Enums
{
    public enum OrderStatus
    {
        Pending,
        Processing,
        Completed,
        Cancelled
    }

    public enum OrderType
    {
        Purchase,
        Reservation,
        Archive
    }

    public enum PaymentStatus
    {
        Unpaid,
        Pending,
        Paid,
        Refunded,
        Failed
    }
}