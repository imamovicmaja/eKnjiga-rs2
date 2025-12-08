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
    public class CityController : BaseCRUDController<CityResponse, CitySearchObject, CityUpsertRequest, CityUpsertRequest>
    {
        public CityController(ICityService service) : base(service)
        {
        }
        
        // Allow anonymous access to GET endpoints only
        [HttpGet]
        [AllowAnonymous]
        public override async Task<PagedResult<CityResponse>> Get([FromQuery] CitySearchObject? search = null)
        {
            return await _service.GetAsync(search ?? new CitySearchObject());
        }
        
        [HttpGet("{id}")]
        [AllowAnonymous]
        public override async Task<CityResponse?> GetById(int id)
        {
            return await _service.GetByIdAsync(id);
        }
    }
} 