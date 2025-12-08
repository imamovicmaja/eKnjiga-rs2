using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace eKnjiga.Services.Database
{
    public class Country
    {
        [Key]
        public int Id { get; set; }
        
        [Required]
        [MaxLength(50)]
        public string Name { get; set; } = string.Empty;
        
        [MaxLength(4)]
        public string Code { get; set; } = string.Empty;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public ICollection<City> Cities { get; set; } = new List<City>();
    }
} 