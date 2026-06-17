using eKnjiga.Model;
using eKnjiga.Model.Requests;
using eKnjiga.Model.Responses;
using eKnjiga.Model.SearchObjects;
using eKnjiga.Model.Constants;
using eKnjiga.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using System;
using System.Threading.Tasks;

namespace eKnjiga.WebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class OrderController : BaseCRUDController<OrderResponse, OrderSearchObject, OrderUpsertRequest, OrderUpdateRequest>
    {
        public OrderController(IOrderService service) : base(service)
        {
        }

        private bool IsAdmin()
        {
            return User.IsInRole(RoleNames.Admin);
        }

        private bool IsEmployee()
        {
            return User.IsInRole(RoleNames.Employee);
        }

        private bool IsStaff()
        {
            return IsAdmin() || IsEmployee();
        }

        private int? GetCurrentUserId()
        {
            var claimValue = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            if (int.TryParse(claimValue, out var userId))
                return userId;

            return null;
        }

        [HttpGet]
        public override async Task<PagedResult<OrderResponse>> Get([FromQuery] OrderSearchObject? search = null)
        {
            search ??= new OrderSearchObject();

            if (!IsStaff())
            {
                var currentUserId = GetCurrentUserId();
                if (currentUserId == null)
                    throw new UnauthorizedAccessException();

                search.UserId = currentUserId.Value;
            }

            return await _service.GetAsync(search);
        }

        [HttpGet("{id}")]
        public override async Task<OrderResponse?> GetById(int id)
        {
            var order = await _service.GetByIdAsync(id);

            if (order == null)
                return null;

            if (!IsStaff())
            {
                var currentUserId = GetCurrentUserId();
                if (currentUserId == null)
                    throw new UnauthorizedAccessException();

                if (order.User == null || order.User.Id != currentUserId.Value)
                    throw new UnauthorizedAccessException();
            }

            return order;
        }

        [HttpPut("{id}/cancel")]
        public async Task<OrderResponse?> Cancel(int id)
        {
            var order = await _service.GetByIdAsync(id);

            if (order == null)
                return null;

            if (!IsStaff())
            {
                var currentUserId = GetCurrentUserId();
                if (currentUserId == null)
                    throw new UnauthorizedAccessException();

                if (order.User == null || order.User.Id != currentUserId.Value)
                    throw new UnauthorizedAccessException();
            }

            return await ((IOrderService)_service).CancelAsync(id);
        }

        [HttpPut("{id}")]
        public override async Task<ActionResult<OrderResponse?>> Update(int id, [FromBody] OrderUpdateRequest request)
        {
            if (!IsStaff())
                return Forbid();

            var result = await ((IOrderService)_service).UpdateAsync(id, request);

            if (result == null)
                return NotFound();

            return Ok(result);
        }

        [HttpGet("report")]
        public async Task<OrderReportResponse> GetReport([FromQuery] OrderReportRequest request)
        {
            return await ((IOrderService)_service).GetReportAsync(request);
        }
    }
}