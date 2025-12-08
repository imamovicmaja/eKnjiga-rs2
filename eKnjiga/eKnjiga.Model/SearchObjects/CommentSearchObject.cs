using System;
using System.Collections.Generic;
using System.Text;

namespace eKnjiga.Model.SearchObjects
{
    public class CommentSearchObject : BaseSearchObject
    {
        public string? Content { get; set; }
        public int? UserId { get; set; }
    }
}
