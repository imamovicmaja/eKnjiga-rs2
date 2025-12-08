using System.Collections.Generic;

namespace eKnjiga.Model.Responses
{
    public class CategoryResponse
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public List<BookResponse> Books { get; set; } = new List<BookResponse>();
    }
}
