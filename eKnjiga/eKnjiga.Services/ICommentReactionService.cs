using eKnjiga.Model.Requests;
using eKnjiga.Model.Responses;
using eKnjiga.Model.SearchObjects;
using System.Threading.Tasks;

namespace eKnjiga.Services
{
    public interface ICommentReactionService
    {
        Task<PagedResult<CommentReactionResponse>> GetAsync(CommentReactionSearchObject search);
        Task<CommentReactionResponse> CreateOrUpdateReactionAsync(CommentReactionRequest request);
        Task<bool> RemoveReactionAsync(CommentReactionRequest request);
    }
}
