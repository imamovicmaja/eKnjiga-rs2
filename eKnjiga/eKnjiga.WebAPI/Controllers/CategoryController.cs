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
    public class CategoryController : BaseCRUDController<CategoryResponse, CategorySearchObject, CategoryUpsertRequest, CategoryUpsertRequest>
    {
        public CategoryController(ICategoryService service) : base(service)
        {
        }
        
        // Allow anonymous access to GET endpoints only
        [HttpGet]
        [AllowAnonymous]
        public override async Task<PagedResult<CategoryResponse>> Get([FromQuery] CategorySearchObject? search = null)
        {
            return await _service.GetAsync(search ?? new CategorySearchObject());
        }
        
        [HttpGet("{id}")]
        [AllowAnonymous]
        public override async Task<CategoryResponse?> GetById(int id)
        {
            return await _service.GetByIdAsync(id);
        }
    }
} 