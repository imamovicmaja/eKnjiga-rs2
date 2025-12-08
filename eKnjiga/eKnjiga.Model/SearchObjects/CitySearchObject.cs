using System;
using System.Collections.Generic;
using System.Text;

namespace eKnjiga.Model.SearchObjects
{
    public class CitySearchObject : BaseSearchObject
    {
        public string? Name { get; set; }
        public int? ZipCode { get; set; }
    }
}
