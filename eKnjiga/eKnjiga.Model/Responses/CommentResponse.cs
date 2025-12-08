using System;
using System.Collections.Generic;

namespace eKnjiga.Model.Responses
{
    public class CommentResponse
    {
        public int Id { get; set; }
        public string Content { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; }
        public int Likes { get; set; }
        public int Dislikes { get; set; }
        public UserResponse? User { get; set; }
        public List<CommentAnswerResponse> Replies { get; set; } = new List<CommentAnswerResponse>();
    }
}
