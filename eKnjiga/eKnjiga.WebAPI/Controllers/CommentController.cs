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
    public class CommentController : BaseCRUDController<CommentResponse, CommentSearchObject, CommentUpsertRequest, CommentUpsertRequest>
    {
        public CommentController(ICommentService service) : base(service)
        {
        }
        
        // Allow anonymous access to GET endpoints only
        [HttpGet]
        [AllowAnonymous]
        public override async Task<PagedResult<CommentResponse>> Get([FromQuery] CommentSearchObject? search = null)
        {
            return await _service.GetAsync(search ?? new CommentSearchObject());
        }
        
        [HttpGet("{id}")]
        [AllowAnonymous]
        public override async Task<CommentResponse?> GetById(int id)
        {
            return await _service.GetByIdAsync(id);
        }
    }
} 