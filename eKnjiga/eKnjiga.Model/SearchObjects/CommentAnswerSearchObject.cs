using System;
using System.Collections.Generic;
using System.Text;

namespace eKnjiga.Model.SearchObjects
{
    public class CommentAnswerSearchObject : BaseSearchObject
    {
        public string? Content { get; set; }
        public int? UserId { get; set; }
        public int? ParentCommentId { get; set; }
    }
}
