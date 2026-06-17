using System;
using System.ComponentModel.DataAnnotations;

namespace eKnjiga.Model.Requests
{
    public class UpdateMyProfileRequest
    {
        [Required(ErrorMessage = "Ime je obavezno. Unesite najmanje 2 slova.")]
        [MinLength(2, ErrorMessage = "Ime mora imati najmanje 2 slova.")]
        [MaxLength(50, ErrorMessage = "Ime može imati najviše 50 znakova.")]
        public string FirstName { get; set; } = string.Empty;

        [Required(ErrorMessage = "Prezime je obavezno. Unesite najmanje 2 slova.")]
        [MinLength(2, ErrorMessage = "Prezime mora imati najmanje 2 slova.")]
        [MaxLength(50, ErrorMessage = "Prezime može imati najviše 50 znakova.")]
        public string LastName { get; set; } = string.Empty;

        [Required(ErrorMessage = "Email je obavezan. Primjer formata: korisnik@example.com.")]
        [EmailAddress(ErrorMessage = "Unesite validan email u formatu: korisnik@example.com.")]
        [MaxLength(100, ErrorMessage = "Email može imati najviše 100 znakova.")]
        public string Email { get; set; } = string.Empty;

        [Required(ErrorMessage = "Korisničko ime je obavezno.")]
        [MinLength(3, ErrorMessage = "Korisničko ime mora imati najmanje 3 znaka.")]
        [MaxLength(50, ErrorMessage = "Korisničko ime može imati najviše 50 znakova.")]
        public string Username { get; set; } = string.Empty;

        [RegularExpression(
            @"^\+?[0-9]{8,15}$",
            ErrorMessage = "Unesite validan broj telefona u formatu: +38761111222 ili 061111222. Broj mora imati 8 do 15 cifara."
        )]
        public string? PhoneNumber { get; set; }

        public DateTime? BirthDate { get; set; }

        [MaxLength(20, ErrorMessage = "Spol može imati najviše 20 znakova.")]
        public string? Gender { get; set; }

        [Required(ErrorMessage = "Grad je obavezan.")]
        [Range(1, int.MaxValue, ErrorMessage = "Odaberite validan grad.")]
        public int CityId { get; set; }

        [MaxLength(100, ErrorMessage = "Stara lozinka može imati najviše 100 znakova.")]
        public string? OldPassword { get; set; }

        [MinLength(6, ErrorMessage = "Nova lozinka mora imati najmanje 6 znakova.")]
        [MaxLength(100, ErrorMessage = "Nova lozinka može imati najviše 100 znakova.")]
        public string? Password { get; set; }

        [MaxLength(100, ErrorMessage = "Potvrda lozinke može imati najviše 100 znakova.")]
        public string? ConfirmPassword { get; set; }

    }
}