using System;
using System.ComponentModel.DataAnnotations;
using System.Collections.Generic;

namespace eKnjiga.Model.Requests
{
    public class AuthorUpsertRequest
    {
        [Required]
        [MaxLength(50)]
        public string FirstName { get; set; } = string.Empty;

        [Required]
        [MaxLength(50)]
        public string LastName { get; set; } = string.Empty;

        public DateTime? BirthDate { get; set; }
        public DateTime? DeathDate { get; set; }

        public string? Description { get; set; }

        public List<int> BookIds { get; set; } = new List<int>();
    }
}
