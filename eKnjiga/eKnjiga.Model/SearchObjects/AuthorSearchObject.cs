using System;
using System.Collections.Generic;
using System.Text;

namespace eKnjiga.Model.SearchObjects
{
    public class AuthorSearchObject : BaseSearchObject
    {
        public string? FirstName { get; set; }
        public string? LastName { get; set; }
    }
}
