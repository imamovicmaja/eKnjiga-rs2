using System;

namespace eKnjiga.Model.Responses
{
    public class CommentAnswerResponse
    {
        public int Id { get; set; }
        public string Content { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; }
        public int Likes { get; set; }
        public int Dislikes { get; set; }
        public UserResponse? User { get; set; }
        public CommentResponse ParentComment { get; set; }
    }
}
