using System;
using System.Collections.Generic;

namespace eKnjiga.Model.Responses
{
    public class UserResponse
    {
        public int Id { get; set; }
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string Username { get; set; } = string.Empty;
        public string? PhoneNumber { get; set; }
        public DateTime? BirthDate { get; set; }
        public string? Gender { get; set; }
        public DateTime CreatedAt { get; set; }
        public CityResponse? City { get; set; }
        public RoleResponse? Role { get; set; }
        public ICollection<BookResponse> UserBooks { get; set; } = new List<BookResponse>();
    }
}
