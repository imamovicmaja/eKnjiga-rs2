using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace eKnjiga.Services.Database
{
    public class Book
    {
        [Key]
        public int Id { get; set; }
        
        [Required]
        [MaxLength(50)]
        public string Name { get; set; } = string.Empty;
        
        [MaxLength(200)]
        public string Description { get; set; } = string.Empty;
        
        [Required] 
        public double Price { get; set; }

        public byte[]? CoverImage { get; set; }

        public byte[]? PdfFile { get; set; }

        public double Rating { get; set; } = 0;

        public int RatingCount { get; set; } = 0;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public ICollection<BookAuthor> BookAuthors { get; set; } = new List<BookAuthor>();

        public ICollection<BookCategory> BookCategories { get; set; } = new List<BookCategory>();

        public ICollection<OrderItem> OrderItems { get; set; } = new List<OrderItem>();
        
        public ICollection<Review> Reviews { get; set; } = new List<Review>();

        public ICollection<UserBook> UserBooks { get; set; } = new List<UserBook>();
    }
} 