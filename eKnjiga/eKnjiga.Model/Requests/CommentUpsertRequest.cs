using System.ComponentModel.DataAnnotations;

namespace eKnjiga.Model.Requests
{
    public class CommentUpsertRequest
    {
        [Required]
        public string Content { get; set; } = string.Empty;

        [Required]
        public int UserId { get; set; }
    }
}
