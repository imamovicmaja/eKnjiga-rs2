using Microsoft.AspNetCore.Http;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace eKnjiga.WebAPI.Requests
{
    public class BookUpsertFormRequest
    {
        [Required]
        [MaxLength(50)]
        public string Name { get; set; } = string.Empty;

        [MaxLength(200)]
        public string Description { get; set; } = string.Empty;

        [Required]
        public double Price { get; set; }

        public IFormFile? CoverImageFile { get; set; }

        public IFormFile? PdfFile { get; set; }

        [Required]
        public List<int> AuthorIds { get; set; } = new();

        [Required]
        public List<int> CategoryIds { get; set; } = new();
    }
}