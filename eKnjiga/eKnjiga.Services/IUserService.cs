using eKnjiga.Services.Database;
using System.Collections.Generic;
using System.Threading.Tasks;
using eKnjiga.Model.Responses;
using eKnjiga.Model.Requests;
using eKnjiga.Model.SearchObjects;

namespace eKnjiga.Services
{
    public interface IUserService
    {
        Task<PagedResult<UserResponse>> GetAsync(UserSearchObject search);
        Task<UserResponse?> GetByIdAsync(int id);
        Task<UserResponse> CreateAsync(UserUpsertRequest request);
        Task<UserResponse?> UpdateAsync(int id, UserUpsertRequest request);
        Task<bool> DeleteAsync(int id);
        Task<UserResponse?> AuthenticateAsync(UserLoginRequest request);
        Task<UserResponse> Register(UserUpsertRequest request);
    }
} 