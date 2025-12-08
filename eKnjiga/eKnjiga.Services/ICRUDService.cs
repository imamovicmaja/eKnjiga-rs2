using eKnjiga.Services.Database;
using System.Collections.Generic;
using System.Threading.Tasks;
using eKnjiga.Model.Responses;
using eKnjiga.Model.Requests;
using eKnjiga.Model.SearchObjects;

namespace eKnjiga.Services
{
    public interface ICRUDService<T, TSearch, TInsert, TUpdate> : IService<T, TSearch> where T : class where TSearch : BaseSearchObject where TInsert : class where TUpdate : class
    {
        Task<T> CreateAsync(TInsert request);
        Task<T?> UpdateAsync(int id, TUpdate request);
        Task<bool> DeleteAsync(int id);
    }
} 