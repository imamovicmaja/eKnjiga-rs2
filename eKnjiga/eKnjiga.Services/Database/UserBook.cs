using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace eKnjiga.Services.Database
{
    public class UserBook
    {
        public int UserId { get; set; }
        [ForeignKey("UserId")]
        public User User { get; set; } = null!;

        public int BookId { get; set; }
        [ForeignKey("BookId")]
        public Book Book { get; set; } = null!;
    }
} 