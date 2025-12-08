namespace eKnjiga.Model.Messages
{
    public class EmailMessage
    {
        public string To { get; set; }
        public string Subject { get; set; }
        public string? Html { get; set; }
        public string? Text { get; set; }
        public string? From { get; set; }
        public string? ReplyTo { get; set; }

        public EmailMessage(
            string to,
            string subject,
            string? html = null,
            string? text = null,
            string? from = null,
            string? replyTo = null)
        {
            To = to;
            Subject = subject;
            Html = html;
            Text = text;
            From = from;
            ReplyTo = replyTo;
        }
    }
}
