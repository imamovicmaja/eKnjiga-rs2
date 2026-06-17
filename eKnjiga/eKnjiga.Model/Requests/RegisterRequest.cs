using System;
using System.ComponentModel.DataAnnotations;

namespace eKnjiga.Model.Requests
{
    public class RegisterRequest
    {
        [Required(ErrorMessage = "Ime je obavezno.")]
        [MaxLength(50)]
        public string FirstName { get; set; } = string.Empty;

        [Required(ErrorMessage = "Prezime je obavezno.")]
        [MaxLength(50)]
        public string LastName { get; set; } = string.Empty;

        [Required(ErrorMessage = "Email je obavezan.")]
        [EmailAddress]
        [MaxLength(100)]
        public string Email { get; set; } = string.Empty;

        [Required(ErrorMessage = "Korisničko ime je obavezno.")]
        [MinLength(3)]
        [MaxLength(100)]
        public string Username { get; set; } = string.Empty;

        [Required(ErrorMessage = "Lozinka je obavezna.")]
        [MinLength(6)]
        [MaxLength(100)]
        public string Password { get; set; } = string.Empty;

        [Phone]
        [MaxLength(20)]
        public string? PhoneNumber { get; set; }

        public DateTime? BirthDate { get; set; }

        [MaxLength(20)]
        public string? Gender { get; set; }

        [Required(ErrorMessage = "Grad je obavezan.")]
        [Range(1, int.MaxValue)]
        public int CityId { get; set; }
    }
}