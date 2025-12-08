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
    public class CommentAnswerController : BaseCRUDController<CommentAnswerResponse, CommentAnswerSearchObject, CommentAnswerUpsertRequest, CommentAnswerUpsertRequest>
    {
        public CommentAnswerController(ICommentAnswerService service) : base(service)
        {
        }
        
        // Allow anonymous access to GET endpoints only
        [HttpGet]
        [AllowAnonymous]
        public override async Task<PagedResult<CommentAnswerResponse>> Get([FromQuery] CommentAnswerSearchObject? search = null)
        {
            return await _service.GetAsync(search ?? new CommentAnswerSearchObject());
        }
        
        [HttpGet("{id}")]
        [AllowAnonymous]
        public override async Task<CommentAnswerResponse?> GetById(int id)
        {
            return await _service.GetByIdAsync(id);
        }
    }
} 