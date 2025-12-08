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
    public class CountryController : BaseCRUDController<CountryResponse, CountrySearchObject, CountryUpsertRequest, CountryUpsertRequest>
    {
        public CountryController(ICountryService service) : base(service)
        {
        }
        
        // Allow anonymous access to GET endpoints only
        [HttpGet]
        [AllowAnonymous]
        public override async Task<PagedResult<CountryResponse>> Get([FromQuery] CountrySearchObject? search = null)
        {
            return await _service.GetAsync(search ?? new CountrySearchObject());
        }
        
        [HttpGet("{id}")]
        [AllowAnonymous]
        public override async Task<CountryResponse?> GetById(int id)
        {
            return await _service.GetByIdAsync(id);
        }
    }
} 