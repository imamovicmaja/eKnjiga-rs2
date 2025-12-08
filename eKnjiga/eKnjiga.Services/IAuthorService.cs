using eKnjiga.Model;
using eKnjiga.Model.Responses;
using eKnjiga.Model.Requests;
using eKnjiga.Model.SearchObjects;
using System.Threading.Tasks;

namespace eKnjiga.Services
{
    public interface IAuthorService : ICRUDService<AuthorResponse, AuthorSearchObject, AuthorUpsertRequest, AuthorUpsertRequest>
    {
    }
}
