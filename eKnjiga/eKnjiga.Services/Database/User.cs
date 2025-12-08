using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace eKnjiga.Services.Database
{
    public class User
    {
        [Key]
        public int Id { get; set; }
        
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
        
        public string PasswordHash { get; set; } = string.Empty;
        
        public string PasswordSalt { get; set; } = string.Empty;
                
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
                
        [Phone]
        [MaxLength(20)]
        public string? PhoneNumber { get; set; }

        public DateTime? BirthDate { get; set; }

        [MaxLength(20)]
        public string? Gender { get; set; }

        public bool IsDeleted { get; set; } = false;
        
        // Foreign key for Role
        public int RoleId { get; set; }
        [ForeignKey("RoleId")]
        public Role Role { get; set; } = null!;

        // Foreign key for City
        public int? CityId { get; set; }
        [ForeignKey("CityId")]
        public City? City { get; set; }

        public ICollection<UserBook> UserBooks { get; set; } = new List<UserBook>();

        public ICollection<Comment> Comments { get; set; } = new List<Comment>();

        public ICollection<Order> Orders { get; set; } = new List<Order>();

        public ICollection<Review> Reviews { get; set; } = new List<Review>();
    }
} 