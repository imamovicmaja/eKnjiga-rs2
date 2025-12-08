using eKnjiga.Model.Requests;
using eKnjiga.Model.Responses;
using eKnjiga.Model.SearchObjects;
using eKnjiga.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Threading.Tasks;

namespace eKnjiga.WebAPI.Controllers
{
    [AllowAnonymous]
    public class BookController : BaseCRUDController<BookResponse, BookSearchObject, BookUpsertRequest, BookUpsertRequest>
    {
        private readonly IBookService _bookService;

        public BookController(IBookService service) : base(service)
        {
            _bookService = service;
        }
        
        // Allow anonymous access to GET endpoints only
        [HttpGet]
        [AllowAnonymous]
        public override async Task<PagedResult<BookResponse>> Get([FromQuery] BookSearchObject? search = null)
        {
            return await _service.GetAsync(search ?? new BookSearchObject());
        }

        [HttpGet("new")]
        public async Task<PagedResult<BookResponse>> GetNew()
        {
            return await _bookService.GetNewAsync();
        }
        
        [HttpGet("{id}")]
        [AllowAnonymous]
        public override async Task<BookResponse?> GetById(int id)
        {
            return await _service.GetByIdAsync(id);
        }

        [HttpGet("recommended")]
        [AllowAnonymous]
        public async Task<IReadOnlyList<BookResponse>> Recommended(
            [FromServices] IRecommendationService rec,
            [FromQuery] int userId,
            [FromQuery] int? categoryId,
            [FromQuery] int count = 10)
        {
            return await rec.GetRecommendedAsync(userId, count, categoryId);
        }

        [HttpGet("similar")]
        [AllowAnonymous]
        public async Task<IReadOnlyList<BookResponse>> Similar(
            [FromServices] IRecommendationService rec,
            [FromQuery] int userId,
            [FromQuery] int bookId,
            [FromQuery] int count = 10)
        {
            return await rec.GetPersonalizedSimilarAsync(userId, bookId, count);
        }
    }
} 