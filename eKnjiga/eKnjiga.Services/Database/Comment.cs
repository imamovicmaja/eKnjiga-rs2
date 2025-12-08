using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace eKnjiga.Services.Database
{
    public class Comment : BaseComment
    {
        public ICollection<CommentAnswer> Replies { get; set; } = new List<CommentAnswer>();
    }
}
