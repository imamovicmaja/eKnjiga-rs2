using System;
using System.ComponentModel.DataAnnotations;

namespace eKnjiga.Model.Requests
{
    public class CityUpsertRequest
    {
        [Required]
        [MaxLength(50)]
        public string Name { get; set; } = string.Empty;

        [Required]
        public int ZipCode { get; set; }

        [Required]
        public int CountryId { get; set; }
    }
}
