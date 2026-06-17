using eKnjiga.Model.Requests;
using eKnjiga.Model.Responses;
using eKnjiga.Model.SearchObjects;
using eKnjiga.Model.Constants;
using eKnjiga.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Threading.Tasks;

namespace eKnjiga.WebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class UserReportController : ControllerBase
    {
        private readonly IUserReportService _service;

        public UserReportController(IUserReportService service)
        {
            _service = service;
        }

        [HttpGet]
        public async Task<ActionResult<PagedResult<UserReportResponse>>> Get(
            [FromQuery] UserReportSearchObject? search = null)
        {
            return await _service.GetAsync(search ?? new UserReportSearchObject());
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<UserReportResponse>> GetById(int id)
        {
            var report = await _service.GetByIdAsync(id);

            if (report == null)
                return NotFound();

            return Ok(report);
        }

        [HttpPost]
        public async Task<ActionResult<UserReportResponse>> Create(
            [FromBody] CreateUserReportRequest request)
        {
            var created = await _service.CreateReportAsync(request);
            return Ok(created);
        }

        [Authorize(Roles = RoleNames.Admin)]
        [HttpPut("{id}/process")]
        public async Task<ActionResult<UserReportResponse>> Process(
            int id,
            [FromBody] ProcessUserReportRequest request)
        {
            var processed = await _service.ProcessReportAsync(id, request);

            if (processed == null)
                return NotFound();

            return Ok(processed);
        }

        [Authorize(Roles = RoleNames.Admin)]
        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(int id)
        {
            var deleted = await _service.DeleteAsync(id);

            if (!deleted)
                return NotFound();

            return NoContent();
        }
    }
}