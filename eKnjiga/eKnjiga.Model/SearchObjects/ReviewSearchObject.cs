using System;
using System.Collections.Generic;
using System.Text;

namespace eKnjiga.Model.SearchObjects
{
    public class ReviewSearchObject : BaseSearchObject
    {
        public int? BookId { get; set; }
        public int? UserId { get; set; }
        public double? Rating { get; set; }
    }
}
