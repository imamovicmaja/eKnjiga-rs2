using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace eKnjiga.Services.Database
{
    public class Review
    {
        [Key]
        public int Id { get; set; }
        
        [Required]
        public double Rating { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        
        // Foreign key for Book
        public int BookId { get; set; }
        [ForeignKey("BookId")]
        public Book Book { get; set; }

        // Foreign key for User
        public int UserId { get; set; }
        [ForeignKey("UserId")]
        public User User { get; set; }
    }
} 