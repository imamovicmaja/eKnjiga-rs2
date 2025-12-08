using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace eKnjiga.Services.Database
{
    public class CommentReaction
    {
        [Key]
        public int Id { get; set; }

        public int? CommentId { get; set; }
        [ForeignKey("CommentId")]
        public Comment? Comment { get; set; }

        public int? CommentAnswerId { get; set; }
        [ForeignKey("CommentAnswerId")]
        public CommentAnswer? CommentAnswer { get; set; }

        public int UserId { get; set; }
        [ForeignKey("UserId")]
        public User User { get; set; } = null!;

        // true = like, false = dislike
        public bool IsLike { get; set; }
    }
}
