using eKnjiga.Model;
using eKnjiga.Model.Responses;
using eKnjiga.Model.Requests;
using eKnjiga.Model.SearchObjects;
using System.Threading.Tasks;

namespace eKnjiga.Services
{
    public interface IOrderService : ICRUDService<OrderResponse, OrderSearchObject, OrderUpsertRequest, OrderUpdateRequest>
    {
    }
}
