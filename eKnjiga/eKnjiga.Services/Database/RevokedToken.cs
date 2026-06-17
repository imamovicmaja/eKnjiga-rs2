namespace eKnjiga.Services.Database
{
    public class RevokedToken
    {
        public int Id { get; set; }
        public string Token { get; set; } = string.Empty;
        public DateTime RevokedAt { get; set; } = DateTime.UtcNow;
        public DateTime ExpiresAt { get; set; }
    }
}