using eKnjiga.Model.Requests;
using eKnjiga.Model.Responses;
using eKnjiga.Model.SearchObjects;
using eKnjiga.Services;
using Microsoft.AspNetCore.Mvc;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace eKnjiga.WebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class UsersController : ControllerBase
    {
        private readonly IUserService _userService;

        public UsersController(IUserService userService)
        {
            _userService = userService;
        }

        [HttpGet]
        public async Task<ActionResult<PagedResult<UserResponse>>> Get([FromQuery] UserSearchObject search)
        {
            return await _userService.GetAsync(search ?? new UserSearchObject());
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<UserResponse>> GetById(int id)
        {
            var user = await _userService.GetByIdAsync(id);
            
            if (user == null)
                return NotFound();
                
            return user;
        }

        [HttpPost]
        public async Task<ActionResult<UserResponse>> Create(UserUpsertRequest request)
        {
            var createdUser = await _userService.CreateAsync(request);
            return CreatedAtAction(nameof(GetById), new { id = createdUser.Id }, createdUser);
        }

        [HttpPut("{id}")]
        public async Task<ActionResult<UserResponse>> Update(int id, UserUpsertRequest request)
        {
            var updatedUser = await _userService.UpdateAsync(id, request);
            
            if (updatedUser == null)
                return NotFound();
                
            return updatedUser;
        }

        [HttpDelete("{id}")]
        public async Task<ActionResult> Delete(int id)
        {
            var deleted = await _userService.DeleteAsync(id);
            
            if (!deleted)
                return NotFound();
                
            return NoContent();
        }

        [HttpPost("login")]
        public async Task<ActionResult<UserResponse>> Login(UserLoginRequest request)
        {
            var user = await _userService.AuthenticateAsync(request);
            return Ok(user);
        }

        [HttpPost("register")]
        public async Task<ActionResult<UserResponse>> Register(UserUpsertRequest request)
        {
            var user = await _userService.Register(request);
            return Ok(user);
        }

        [HttpPut("{id}/profile-image")]
        [Consumes("multipart/form-data")]
        public async Task<ActionResult<UserResponse>> UpdateProfileImage(int id, [FromForm] IFormFile file)
        {
            if (file == null || file.Length == 0)
                return BadRequest("File is required.");

            const long maxBytes = 2 * 1024 * 1024;
            if (file.Length > maxBytes)
                return BadRequest("File is too large (max 2MB).");

            if (file.ContentType != "image/jpeg" && file.ContentType != "image/png")
                return BadRequest("Only JPG and PNG are allowed.");

            byte[] bytes;
            using (var ms = new MemoryStream())
            {
                await file.CopyToAsync(ms);
                bytes = ms.ToArray();
            }

            var updated = await _userService.UpdateProfileImageAsync(id, bytes);
            if (updated == null)
                return NotFound();

            return Ok(updated);
        }
    }
} 