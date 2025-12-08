using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace eKnjiga.Services.Database
{
    public class CommentAnswer : BaseComment
    {
        public int? ParentCommentId { get; set; }

        [ForeignKey("ParentCommentId")]
        public Comment? ParentComment { get; set; }
    }
}