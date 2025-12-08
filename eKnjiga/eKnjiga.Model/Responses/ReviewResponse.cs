using System;

namespace eKnjiga.Model.Responses
{
    public class ReviewResponse
    {
        public int Id { get; set; }
        public double Rating { get; set; }
        public DateTime CreatedAt { get; set; }
        public BookResponse? Book { get; set; }
        public UserResponse? User { get; set; }
    }
}
