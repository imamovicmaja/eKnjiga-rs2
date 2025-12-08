  using eKnjiga.Model.Responses;
  using eKnjiga.Model.SearchObjects;
  using eKnjiga.Model.Requests;
  using eKnjiga.Services.Database;
  using System.Threading.Tasks;

  namespace eKnjiga.Services
  {
      public interface IBookService : ICRUDService<BookResponse, BookSearchObject, BookUpsertRequest, BookUpsertRequest>
      {
        Task<PagedResult<BookResponse>> GetNewAsync();
      }
  }
