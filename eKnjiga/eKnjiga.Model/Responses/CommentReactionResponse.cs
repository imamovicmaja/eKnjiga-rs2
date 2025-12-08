namespace eKnjiga.Model.Responses
{
    public class CommentReactionResponse
    {
        public bool IsUpdated { get; set; }
        public bool IsLike { get; set; }
        public int UserId { get; set; }
        public int? CommentId { get; set; }
        public int? CommentAnswerId { get; set; }
    }
}
