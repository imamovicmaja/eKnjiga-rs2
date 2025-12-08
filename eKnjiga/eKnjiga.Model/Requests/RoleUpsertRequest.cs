using System.ComponentModel.DataAnnotations;

namespace eKnjiga.Model.Requests
{
    public class RoleUpsertRequest
    {
        [Required]
        [MaxLength(50)]
        public string Name { get; set; } = string.Empty;

        [MaxLength(200)]
        public string Description { get; set; } = string.Empty;
    }
}
