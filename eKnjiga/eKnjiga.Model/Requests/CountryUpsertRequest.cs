using System.ComponentModel.DataAnnotations;

namespace eKnjiga.Model.Requests
{
    public class CountryUpsertRequest
    {
        [Required]
        [MaxLength(50)]
        public string Name { get; set; } = string.Empty;

        [MaxLength(4)]
        public string Code { get; set; } = string.Empty;
    }
}
