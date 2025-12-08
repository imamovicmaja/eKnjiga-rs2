using System.Collections.Generic;
using System.Threading.Tasks;
using eKnjiga.Model.Responses;

namespace eKnjiga.Services
{
    public interface IRecommendationService
    {
        Task<IReadOnlyList<BookResponse>> GetRecommendedAsync(int userId, int count = 10, int? categoryId = null);
        Task<IReadOnlyList<BookResponse>> GetPersonalizedSimilarAsync(int userId, int bookId, int count = 10);
    }
}
