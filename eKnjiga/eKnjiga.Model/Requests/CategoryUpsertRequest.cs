using System;
using System.ComponentModel.DataAnnotations;
using System.Collections.Generic;

namespace eKnjiga.Model.Requests
{
    public class CategoryUpsertRequest
    {
        [Required]
        [MaxLength(50)]
        public string Name { get; set; } = string.Empty;

        public List<int> BookIds { get; set; } = new List<int>();
    }
}
