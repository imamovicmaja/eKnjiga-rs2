using eKnjiga.Model.Requests;
using eKnjiga.Model.Responses;
using eKnjiga.Model.SearchObjects;
using eKnjiga.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Threading.Tasks;
using System.Security.Claims;

namespace eKnjiga.WebAPI.Controllers
{
    [AllowAnonymous]
    public class UserReportController : BaseCRUDController<UserReportResponse, UserReportSearchObject, UserReportUpsertRequest, UserReportUpsertRequest>
    {
        public UserReportController(IUserReportService service) : base(service)
        {
        }
        
        // Allow anonymous access to GET endpoints only
        [HttpGet]
        [AllowAnonymous]
        public override async Task<PagedResult<UserReportResponse>> Get([FromQuery] UserReportSearchObject? search = null)
        {
            return await _service.GetAsync(search ?? new UserReportSearchObject());
        }
        
        [HttpGet("{id}")]
        [AllowAnonymous]
        public override async Task<UserReportResponse?> GetById(int id)
        {
            return await _service.GetByIdAsync(id);
        }

        private int LoggedUserId()
        {
            var idStr = User.FindFirst("id")?.Value
                        ?? User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            if (int.TryParse(idStr, out var id))
                return id;

            throw new InvalidOperationException("Cannot resolve logged in user id.");
        }

        [HttpPut("{id}")]
        public override async Task<ActionResult<UserReportResponse?>> Update(int id, [FromBody] UserReportUpsertRequest request)
        {
            request.ProcessedByUserId = LoggedUserId();

            var result = await _crudService.UpdateAsync(id, request);

            if (result == null)
                return NotFound(new { message = "Entity not found." });

            return Ok(result);
        }
    }
} 