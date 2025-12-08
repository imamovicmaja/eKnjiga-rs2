using System;
using System.Collections.Generic;
using System.Text;

namespace eKnjiga.Model.SearchObjects
{
    public class BaseSearchObject
    {
        public int? Page { get; set; } = 0;
        public int? PageSize { get; set; } = 100;
        public bool IncludeTotalCount { get; set; } = false;
        public bool RetrieveAll { get; set; } = false;
    }
} 