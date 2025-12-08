using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace eKnjiga.Services.Database
{
    public class City
    {
        [Key]
        public int Id { get; set; }
        
        [Required]
        [MaxLength(50)]
        public string Name { get; set; } = string.Empty;
        
        public int ZipCode { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        // Foreign key for Country
        public int CountryId { get; set; }
        [ForeignKey("CountryId")]
        public Country Country { get; set; }

        public ICollection<User> Users { get; set; }
    }
} 