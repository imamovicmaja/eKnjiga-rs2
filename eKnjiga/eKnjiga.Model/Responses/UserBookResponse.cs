using System;

namespace eKnjiga.Model.Responses
{
    public class UserBookResponse
    {
        public int BookId { get; set; }
        public bool IsFavorite { get; set; }
        public BookResponse Book { get; set; } = null!;
    }
}