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
    public class AuthorController : BaseCRUDController<AuthorResponse, AuthorSearchObject, AuthorUpsertRequest, AuthorUpsertRequest>
    {
        public AuthorController(IAuthorService service) : base(service)
        {
        }
        
        // Allow anonymous access to GET endpoints only
        [HttpGet]
        [AllowAnonymous]
        public override async Task<PagedResult<AuthorResponse>> Get([FromQuery] AuthorSearchObject? search = null)
        {
            return await _service.GetAsync(search ?? new AuthorSearchObject());
        }
        
        [HttpGet("{id}")]
        [AllowAnonymous]
        public override async Task<AuthorResponse?> GetById(int id)
        {
            return await _service.GetByIdAsync(id);
        }
    }
} 