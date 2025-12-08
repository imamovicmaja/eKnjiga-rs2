using eKnjiga.Model.Requests;
using eKnjiga.Model.Responses;
using eKnjiga.Model.SearchObjects;

namespace eKnjiga.Services
{
    public interface IRoleService : ICRUDService<RoleResponse, RoleSearchObject, RoleUpsertRequest, RoleUpsertRequest>
    {
        Task<RoleResponse?> GetByNameAsync(string name);
    }
} 