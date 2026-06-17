using System;
using System.Collections.Generic;

namespace eKnjiga.Model.Responses
{
    public class BookListResponse
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public double Rating { get; set; }
        public int RatingCount { get; set; }
        public string? CoverImage { get; set; }
        public string? WhyRecommended { get; set; }

        public List<AuthorResponse> Authors { get; set; } = new();
    }
}