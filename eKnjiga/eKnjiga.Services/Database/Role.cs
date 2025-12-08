using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace eKnjiga.Services.Database
{
    public class Role
    {
        [Key]
        public int Id { get; set; }
        
        [Required]
        [MaxLength(50)]
        public string Name { get; set; } = string.Empty;
        
        [MaxLength(200)]
        public string Description { get; set; } = string.Empty;
        
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public ICollection<User> Users { get; set; } = new List<User>();
    }
} 