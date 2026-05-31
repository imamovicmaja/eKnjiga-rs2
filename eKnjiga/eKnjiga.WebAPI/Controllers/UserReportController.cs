using eKnjiga.Model;
using eKnjiga.Model.Requests;
using eKnjiga.Model.Responses;
using eKnjiga.Model.SearchObjects;
using eKnjiga.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Threading.Tasks;

namespace eKnjiga.WebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class UserReportController : BaseCRUDController<UserReportResponse, UserReportSearchObject, UserReportUpsertRequest, UserReportUpsertRequest>
    {
        public UserReportController(IUserReportService service) : base(service)
        {
           
        }

        [HttpGet]
        public override async Task<PagedResult<UserReportResponse>> Get([FromQuery] UserReportSearchObject? search = null)
        {
            return await _service.GetAsync(search ?? new UserReportSearchObject());
        }

        [HttpGet("{id}")]
        public override async Task<UserReportResponse?> GetById(int id)
        {
            return await _service.GetByIdAsync(id);
        }
    }
}