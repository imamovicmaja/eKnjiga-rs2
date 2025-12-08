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
    public class OrderController : BaseCRUDController<OrderResponse, OrderSearchObject, OrderUpsertRequest, OrderUpdateRequest>
    {
        public OrderController(IOrderService service) : base(service)
        {
        }
        
        // Allow anonymous access to GET endpoints only
        [HttpGet]
        [AllowAnonymous]
        public override async Task<PagedResult<OrderResponse>> Get([FromQuery] OrderSearchObject? search = null)
        {
            return await _service.GetAsync(search ?? new OrderSearchObject());
        }
        
        [HttpGet("{id}")]
        [AllowAnonymous]
        public override async Task<OrderResponse?> GetById(int id)
        {
            return await _service.GetByIdAsync(id);
        }
    }
} 