using System;
using System.Collections.Generic;

namespace eKnjiga.Model.Responses
{
    public class AuthorResponse
    {
        public int Id { get; set; }
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;

        public DateTime? BirthDate { get; set; }
        public DateTime? DeathDate { get; set; }

        public string? Description { get; set; }

        public List<BookResponse> Books { get; set; } = new List<BookResponse>();
    }
}
