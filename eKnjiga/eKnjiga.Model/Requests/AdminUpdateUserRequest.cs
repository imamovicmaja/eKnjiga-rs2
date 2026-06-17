using System.ComponentModel.DataAnnotations;

namespace eKnjiga.Model.Requests
{
    public class AdminUpdateUserRequest : UpdateMyProfileRequest
    {
        [Required]
        [Range(1, int.MaxValue, ErrorMessage = "Odaberite ulogu.")]
        public int RoleId { get; set; }
    }
}