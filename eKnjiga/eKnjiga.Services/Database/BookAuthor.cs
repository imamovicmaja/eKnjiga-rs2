using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace eKnjiga.Services.Database
{
    public class BookAuthor
    {
        public int BookId { get; set; }
        [ForeignKey("BookId")]
        public Book Book { get; set; } = null!;

        public int AuthorId { get; set; }
        [ForeignKey("AuthorId")]
        public Author Author { get; set; } = null!;
    }
} 