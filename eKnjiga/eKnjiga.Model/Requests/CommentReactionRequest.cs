namespace eKnjiga.Model.Requests
{
    public class CommentReactionRequest
    {
        public int UserId { get; set; }
        public int? CommentId { get; set; }
        public int? CommentAnswerId { get; set; }
        public bool IsLike { get; set; }
    }
}
