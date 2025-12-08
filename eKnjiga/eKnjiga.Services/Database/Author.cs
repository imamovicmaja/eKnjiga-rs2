using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace eKnjiga.Services.Database
{
    public class Author
    {
        [Key]
        public int Id { get; set; }
        
        [Required]
        [MaxLength(50)]
        public string FirstName { get; set; } = string.Empty;

        [Required]
        [MaxLength(50)]
        public string LastName { get; set; } = string.Empty;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public DateTime? BirthDate { get; set; }
        public DateTime? DeathDate { get; set; }

        [MaxLength(2000)]
        public string? Description { get; set; }
        
        public ICollection<BookAuthor> BookAuthors { get; set; } = new List<BookAuthor>();
    }
} 