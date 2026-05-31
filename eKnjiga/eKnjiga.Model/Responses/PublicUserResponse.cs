using System;
using System.Collections.Generic;
using System.Text;

namespace eKnjiga.Model.Responses
{
    public class PublicUserResponse
    {
        public int Id { get; set; }
        public string Username { get; set; } = string.Empty;
        public string? FirstName { get; set; }
        public string? LastName { get; set; }
        public string? ProfileImage { get; set; }
    }
}
