using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace eKnjiga.Model.Requests
{
    public class BookUpsertRequest
    {
        [Required]
        [MaxLength(50)]
        public string Name { get; set; } = string.Empty;

        [MaxLength(200)]
        public string Description { get; set; } = string.Empty;

        [Required]
        public double Price { get; set; }

        public byte[]? CoverImage { get; set; }

        public byte[]? PdfFile { get; set; }

        [Required]
        public List<int> AuthorIds { get; set; } = new List<int>();

        [Required]
        public List<int> CategoryIds { get; set; } = new List<int>();
    }
}
