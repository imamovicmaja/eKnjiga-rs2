using eKnjiga.Model.Requests;
using eKnjiga.Model.Responses;
using eKnjiga.Model.SearchObjects;
using eKnjiga.Model.Constants;
using eKnjiga.Services;
using eKnjiga.WebAPI.Helpers;
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
        private readonly IJwtService _jwtService;

        public UsersController(IUserService userService, IJwtService jwtService)
        {
            _userService = userService;
            _jwtService = jwtService;
        }

        private bool IsAdmin()
        {
            return User.IsInRole(RoleNames.Admin);
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

        [Authorize(Roles = RoleNames.Admin)]
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

        [Authorize(Roles = RoleNames.Admin)]
        [HttpPost]
        public async Task<ActionResult<UserResponse>> Create([FromBody] UserUpsertRequest request)
        {
            var createdUser = await _userService.CreateAsync(request);
            return CreatedAtAction(nameof(GetById), new { id = createdUser.Id }, createdUser);
        }

        [Authorize(Roles = RoleNames.Admin)]
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
        public async Task<ActionResult<LoginResponse>> Login([FromBody] UserLoginRequest request)
        {
            var user = await _userService.AuthenticateAsync(request);

            if (user == null)
                return Unauthorized("Pogrešno korisničko ime ili lozinka.");

            var loginResponse = _jwtService.GenerateToken(user);

            return Ok(loginResponse);
        }

        [Authorize(Roles = RoleNames.Admin)]
        [HttpPut("{id}")]
        public async Task<ActionResult<UserResponse>> AdminUpdate(int id, [FromBody] AdminUpdateUserRequest request)
        {
            var updatedUser = await _userService.AdminUpdateAsync(id, request);

            if (updatedUser == null)
                return NotFound();

            return Ok(updatedUser);
        }

        [HttpPut("{id}/profile")]
        public async Task<ActionResult<UserResponse>> UpdateMyProfile(int id, [FromBody] UpdateMyProfileRequest request)
        {
            var currentUserId = GetCurrentUserId();

            if (currentUserId == null || currentUserId.Value != id)
                return Forbid();

            var updatedUser = await _userService.UpdateMyProfileAsync(id, request);

            if (updatedUser == null)
                return NotFound();

            return Ok(updatedUser);
        }

        [AllowAnonymous]
        [HttpPost("register")]
        public async Task<ActionResult<UserResponse>> Register([FromBody] RegisterRequest request)
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

            try
            {
                await FileUploadValidator.ValidateImageAsync(file);

                var updated = await _userService.UpdateProfileImageAsync(id, file);

                if (updated == null)
                    return NotFound();

                return Ok(updated);
            }
            catch (Exception ex)
            {
                return BadRequest(ex.Message);
            }
        }

        [HttpPut("books/{bookId}/favorite")]
        public async Task<IActionResult> SetFavorite(int bookId, [FromBody] bool isFavorite)
        {
            var currentUserId = GetCurrentUserId();

            if (currentUserId == null)
                return Unauthorized();

            try
            {
                await _userService.SetFavoriteAsync(currentUserId.Value, bookId, isFavorite);
                return Ok();
            }
            catch (KeyNotFoundException ex)
            {
                return NotFound(ex.Message);
            }
        }

        [HttpGet("books/{bookId}/favorite")]
        public async Task<IActionResult> GetFavorite(int bookId)
        {
            var currentUserId = GetCurrentUserId();

            if (currentUserId == null)
                return Unauthorized();

            try
            {
                var isFavorite = await _userService.GetFavoriteAsync(currentUserId.Value, bookId);
                return Ok(isFavorite);
            }
            catch (KeyNotFoundException ex)
            {
                return NotFound(ex.Message);
            }
        }

        [Authorize]
        [HttpPost("logout")]
        public async Task<IActionResult> Logout()
        {
            var authHeader = Request.Headers["Authorization"].ToString();

            if (string.IsNullOrWhiteSpace(authHeader) || !authHeader.StartsWith("Bearer "))
                return BadRequest("Token nije pronađen.");

            var token = authHeader.Replace("Bearer ", "");

            var handler = new System.IdentityModel.Tokens.Jwt.JwtSecurityTokenHandler();
            var jwtToken = handler.ReadJwtToken(token);

            var expiresAt = jwtToken.ValidTo;

            await _userService.RevokeTokenAsync(token, expiresAt);

            return NoContent();
        }
    }
}