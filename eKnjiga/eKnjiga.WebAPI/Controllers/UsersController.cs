using eKnjiga.Model.Requests;
using eKnjiga.Model.Responses;
using eKnjiga.Model.SearchObjects;
using eKnjiga.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.IO;
using System.Security.Claims;
using System.Threading.Tasks;

namespace eKnjiga.WebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class UsersController : ControllerBase
    {
        private readonly IUserService _userService;

        public UsersController(IUserService userService)
        {
            _userService = userService;
        }

        private bool IsAdmin()
        {
            return User.IsInRole("Admin");
        }

        private int? GetCurrentUserId()
        {
            var claimValue = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            if (int.TryParse(claimValue, out var userId))
                return userId;

            return null;
        }

        private bool IsAdminOrOwner(int id)
        {
            var currentUserId = GetCurrentUserId();

            if (currentUserId == null)
                return false;

            return IsAdmin() || currentUserId.Value == id;
        }

        [Authorize(Roles = "Admin")]
        [HttpGet]
        public async Task<ActionResult<PagedResult<UserResponse>>> Get([FromQuery] UserSearchObject search)
        {
            return await _userService.GetAsync(search ?? new UserSearchObject());
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<UserResponse>> GetById(int id)
        {
            if (!IsAdminOrOwner(id))
                return Forbid();

            var user = await _userService.GetByIdAsync(id);

            if (user == null)
                return NotFound();

            return Ok(user);
        }

        [Authorize(Roles = "Admin")]
        [HttpPost]
        public async Task<ActionResult<UserResponse>> Create([FromBody] UserUpsertRequest request)
        {
            var createdUser = await _userService.CreateAsync(request);
            return CreatedAtAction(nameof(GetById), new { id = createdUser.Id }, createdUser);
        }

        [HttpPut("{id}")]
        public async Task<ActionResult<UserResponse>> Update(int id, [FromBody] UserUpsertRequest request)
        {
            if (!IsAdminOrOwner(id))
                return Forbid();

            var updatedUser = await _userService.UpdateAsync(id, request);

            if (updatedUser == null)
                return NotFound();

            return Ok(updatedUser);
        }

        [Authorize(Roles = "Admin")]
        [HttpDelete("{id}")]
        public async Task<ActionResult> Delete(int id)
        {
            var deleted = await _userService.DeleteAsync(id);

            if (!deleted)
                return NotFound();

            return NoContent();
        }

        [AllowAnonymous]
        [HttpPost("login")]
        public async Task<ActionResult<UserResponse>> Login([FromBody] UserLoginRequest request)
        {
            var user = await _userService.AuthenticateAsync(request);

            if (user == null)
                return Unauthorized();

            return Ok(user);
        }

        [AllowAnonymous]
        [HttpPost("register")]
        public async Task<ActionResult<UserResponse>> Register([FromBody] UserUpsertRequest request)
        {
            var user = await _userService.Register(request);
            return Ok(user);
        }

        [HttpPut("{id}/profile-image")]
        [Consumes("multipart/form-data")]
        public async Task<ActionResult<UserResponse>> UpdateProfileImage(int id, [FromForm] IFormFile file)
        {
            if (!IsAdminOrOwner(id))
                return Forbid();

            if (file == null || file.Length == 0)
                return BadRequest("File is required.");

            const long maxBytes = 2 * 1024 * 1024;
            if (file.Length > maxBytes)
                return BadRequest("File is too large (max 2MB).");

            if (file.ContentType != "image/jpeg" && file.ContentType != "image/png")
                return BadRequest("Only JPG and PNG are allowed.");

            var updated = await _userService.UpdateProfileImageAsync(id, file);

            if (updated == null)
                return NotFound();

            return Ok(updated);
        }

        [HttpPut("{userId}/books/{bookId}/favorite")]
        public async Task<IActionResult> SetFavorite(int userId, int bookId, [FromBody] bool isFavorite)
        {
            if (!IsAdminOrOwner(userId))
                return Forbid();

            try
            {
                await _userService.SetFavoriteAsync(userId, bookId, isFavorite);
                return Ok();
            }
            catch (KeyNotFoundException ex)
            {
                return NotFound(ex.Message);
            }
        }

        [HttpGet("{userId}/books/{bookId}/favorite")]
        public async Task<IActionResult> GetFavorite(int userId, int bookId)
        {
            if (!IsAdminOrOwner(userId))
                return Forbid();

            try
            {
                var isFavorite = await _userService.GetFavoriteAsync(userId, bookId);
                return Ok(isFavorite);
            }
            catch (KeyNotFoundException ex)
            {
                return NotFound(ex.Message);
            }
        }
    }
}