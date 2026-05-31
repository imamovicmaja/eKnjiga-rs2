using eKnjiga.Model;
using eKnjiga.Model.Requests;
using eKnjiga.Model.Responses;
using eKnjiga.Model.SearchObjects;

namespace eKnjiga.Services
{
    public interface IBookService
    {
        Task<PagedResult<BookListResponse>> GetAsync(BookSearchObject search);
        Task<PagedResult<BookListResponse>> GetNewAsync();
        Task<BookResponse?> GetByIdAsync(int id);
        Task<byte[]?> GetPdfAsync(int id);
        Task<byte[]?> GetPdfForUserAsync(int bookId, int userId);
        Task<BookResponse> InsertAsync(BookUpsertRequest request);
        Task<BookResponse?> UpdateAsync(int id, BookUpsertRequest request);
        Task<bool> DeleteAsync(int id);

        Task<bool> UpdateCoverAsync(int id, string coverImagePath);
        Task<bool> UpdatePdfAsync(int id, byte[] pdfBytes);
    }
}