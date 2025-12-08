using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace eKnjiga.Model.Requests
{
    public class UserUpsertRequest
    {
        [Required]
        [MaxLength(50)]
        public string FirstName { get; set; } = string.Empty;
        
        [Required]
        [MaxLength(50)]
        public string LastName { get; set; } = string.Empty;
        
        [Required]
        [MaxLength(100)]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;
        
        [Required]
        [MaxLength(100)]
        public string Username { get; set; } = string.Empty;
        
        [MaxLength(20)]
        [Phone]
        public string? PhoneNumber { get; set; }

        public DateTime? BirthDate { get; set; }

        [MaxLength(20)]
        public string? Gender { get; set; }
                
        // Only used when creating a new user
        [MinLength(6)]
        public string? Password { get; set; }
        
        [Required]
        public int RoleId { get; set; }

        public int CityId { get; set; }
    }
} 