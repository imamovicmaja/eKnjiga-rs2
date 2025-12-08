using System;
using System.Collections.Generic;
using System.Text;

namespace eKnjiga.Model.SearchObjects
{
    public class BookSearchObject : BaseSearchObject
    {
        public string? Name { get; set; }
        public int? CategoryId { get; set; }
    }
}
