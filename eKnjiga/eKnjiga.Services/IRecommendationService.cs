using eKnjiga.Model.Responses;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace eKnjiga.Services
{
    public interface IRecommendationService
    {
        Task<IReadOnlyList<BookListResponse>> GetRecommendedAsync(int userId, int count = 10, int? categoryId = null);
        Task<IReadOnlyList<BookListResponse>> GetPersonalizedSimilarAsync(int userId, int bookId, int count = 10);
    }
}