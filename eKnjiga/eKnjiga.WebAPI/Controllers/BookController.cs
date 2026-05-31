using eKnjiga.Model;
using eKnjiga.Model.Requests;
using eKnjiga.Model.Responses;
using eKnjiga.Model.SearchObjects;
using eKnjiga.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace eKnjiga.WebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class BookController : ControllerBase
    {
        private readonly IBookService _bookService;
        private readonly IRecommendationService _recommendationService;
        private readonly IWebHostEnvironment _environment;

        public BookController(
            IBookService bookService,
            IRecommendationService recommendationService,
            IWebHostEnvironment environment)
        {
            _bookService = bookService;
            _recommendationService = recommendationService;
            _environment = environment;
        }

        [HttpGet]
        [AllowAnonymous]
        public async Task<PagedResult<BookListResponse>> Get([FromQuery] BookSearchObject? search = null)
        {
            return await _bookService.GetAsync(search ?? new BookSearchObject());
        }

        [HttpGet("new")]
        [AllowAnonymous]
        public async Task<PagedResult<BookListResponse>> GetNew()
        {
            return await _bookService.GetNewAsync();
        }

        [HttpGet("{id}")]
        [AllowAnonymous]
        public async Task<ActionResult<BookResponse>> GetById(int id)
        {
            var result = await _bookService.GetByIdAsync(id);

            if (result == null)
                return NotFound();

            return Ok(result);
        }

        private int? GetCurrentUserId()
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            if (int.TryParse(userIdClaim, out var userId))
                return userId;

            return null;
        }

        [HttpGet("{id}/pdf")]
        [Authorize]
        public async Task<IActionResult> GetPdf(int id)
        {
            var currentUserId = GetCurrentUserId();

            if (currentUserId == null)
                return Unauthorized();

            var pdf = await _bookService.GetPdfForUserAsync(id, currentUserId.Value);

            if (pdf == null || pdf.Length == 0)
                return NotFound();

            return File(pdf, "application/pdf");
        }

        [HttpGet("recommended")]
        [Authorize]
        public async Task<ActionResult<IReadOnlyList<BookListResponse>>> Recommended(
            [FromQuery] int? categoryId,
            [FromQuery] int count = 10)
        {
            var currentUserId = GetCurrentUserId();

            if (currentUserId == null)
                return Unauthorized();

            var result = await _recommendationService.GetRecommendedAsync(currentUserId.Value, count, categoryId);
            return Ok(result);
        }

        [HttpGet("similar")]
        [Authorize]
        public async Task<ActionResult<IReadOnlyList<BookListResponse>>> Similar(
            [FromQuery] int bookId,
            [FromQuery] int count = 10)
        {
            var currentUserId = GetCurrentUserId();

            if (currentUserId == null)
                return Unauthorized();

            var result = await _recommendationService.GetPersonalizedSimilarAsync(currentUserId.Value, bookId, count);
            return Ok(result);
        }

        [HttpPost]
        [Authorize(Roles = "Admin")]
        public async Task<ActionResult<BookResponse>> Insert([FromBody] BookUpsertRequest request)
        {
            var result = await _bookService.InsertAsync(request);
            return Ok(result);
        }

        [HttpPut("{id}")]
        [Authorize(Roles = "Admin")]
        public async Task<ActionResult<BookResponse>> Update(int id, [FromBody] BookUpsertRequest request)
        {
            var result = await _bookService.UpdateAsync(id, request);

            if (result == null)
                return NotFound();

            return Ok(result);
        }

        [HttpPut("{id}/cover")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> UploadCover(int id, IFormFile file)
        {
            if (file == null || file.Length == 0)
                return BadRequest("Fajl nije poslan.");

            var imagePath = await SaveImage(file);

            var success = await _bookService.UpdateCoverAsync(id, imagePath);

            if (!success)
                return NotFound();

            return Ok(new { coverImage = imagePath });
        }

        [HttpPut("{id}/pdf-upload")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> UploadPdf(int id, IFormFile file)
        {
            if (file == null || file.Length == 0)
                return BadRequest("Fajl nije poslan.");

            using var ms = new MemoryStream();
            await file.CopyToAsync(ms);

            var success = await _bookService.UpdatePdfAsync(id, ms.ToArray());

            if (!success)
                return NotFound();

            return Ok();
        }

        [HttpDelete("{id}")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> Delete(int id)
        {
            var deleted = await _bookService.DeleteAsync(id);

            if (!deleted)
                return NotFound();

            return NoContent();
        }

        private async Task<string> SaveImage(IFormFile file)
        {
            if (file == null || file.Length == 0)
                throw new Exception("Fajl nije poslan.");

            if (file.Length > 1024 * 1024)
                throw new Exception("Slika mora biti manja od 1 MB.");

            var webRoot = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot");
            var folderPath = Path.Combine(webRoot, "images", "books");

            if (!Directory.Exists(folderPath))
                Directory.CreateDirectory(folderPath);

            var fileName = $"{Guid.NewGuid()}{Path.GetExtension(file.FileName)}";
            var fullPath = Path.Combine(folderPath, fileName);

            using (var stream = new FileStream(fullPath, FileMode.Create))
            {
                await file.CopyToAsync(stream);
            }

            return $"/images/books/{fileName}";
        }
    }
}