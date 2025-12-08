using System;
using System.Collections.Generic;

namespace eKnjiga.Model.Responses
{
    public class BookResponse
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public double Price { get; set; }
        public byte[] CoverImage { get; set; } = Array.Empty<byte>();
        public byte[] PdfFile { get; set; } = Array.Empty<byte>();
        public double Rating { get; set; }
        public int RatingCount { get; set; }
        public DateTime CreatedAt { get; set; }
        
        public List<AuthorResponse> Authors { get; set; } = new List<AuthorResponse>();
        public List<CategoryResponse> Categories { get; set; } = new List<CategoryResponse>();
    }
}
