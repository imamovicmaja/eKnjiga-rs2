using eKnjiga.Model.Requests;
using eKnjiga.Model.Responses;
using eKnjiga.Model.SearchObjects;
using eKnjiga.Services.Database;
using Microsoft.EntityFrameworkCore;

namespace eKnjiga.Services
{
    public class CommentReactionService : ICommentReactionService
    {
        private readonly eKnjigaDbContext _context;

        public CommentReactionService(eKnjigaDbContext context)
        {
            _context = context;
        }

        public async Task<PagedResult<CommentReactionResponse>> GetAsync(CommentReactionSearchObject search)
        {
            var query = _context.CommentReactions.AsQueryable();

            query = ApplyFilter(query, search);

            int? totalCount = null;
            if (search.IncludeTotalCount)
                totalCount = await query.CountAsync();

            if (!search.RetrieveAll)
            {
                if (search.Page.HasValue)
                    query = query.Skip(search.Page.Value * search.PageSize.Value);
                if (search.PageSize.HasValue)
                    query = query.Take(search.PageSize.Value);
            }

            var list = await query.ToListAsync();
            return new PagedResult<CommentReactionResponse>
            {
                Items = list.Select(MapToResponse).ToList(),
                TotalCount = totalCount
            };
        }

        public async Task<CommentReactionResponse> CreateOrUpdateReactionAsync(CommentReactionRequest request)
        {
            if ((request.CommentId == null && request.CommentAnswerId == null) ||
                (request.CommentId != null && request.CommentAnswerId != null))
            {
                throw new ArgumentException("Potrebno je navesti tačno jedan od CommentId ili CommentAnswerId.");
            }

            var existing = await _context.CommentReactions
                .FirstOrDefaultAsync(r =>
                    r.UserId == request.UserId &&
                    r.CommentId == request.CommentId &&
                    r.CommentAnswerId == request.CommentAnswerId);

            if (existing != null)
            {
                existing.IsLike = request.IsLike;
                await _context.SaveChangesAsync();

                return new CommentReactionResponse
                {
                    IsUpdated = true,
                    IsLike = request.IsLike
                };
            }
            else
            {
                var newReaction = new CommentReaction
                {
                    UserId = request.UserId,
                    CommentId = request.CommentId,
                    CommentAnswerId = request.CommentAnswerId,
                    IsLike = request.IsLike
                };

                _context.CommentReactions.Add(newReaction);
                await _context.SaveChangesAsync();

                return new CommentReactionResponse
                {
                    IsUpdated = false,
                    IsLike = request.IsLike
                };
            }
        }

        public async Task<bool> RemoveReactionAsync(CommentReactionRequest request)
        {
            if ((request.CommentId == null && request.CommentAnswerId == null) ||
                (request.CommentId != null && request.CommentAnswerId != null))
            {
                throw new ArgumentException("Potrebno je navesti tačno jedan od CommentId ili CommentAnswerId.");
            }

            var existing = await _context.CommentReactions
                .FirstOrDefaultAsync(r =>
                    r.UserId == request.UserId &&
                    r.CommentId == request.CommentId &&
                    r.CommentAnswerId == request.CommentAnswerId);

            if (existing != null)
            {
                _context.CommentReactions.Remove(existing);
                await _context.SaveChangesAsync();
                return true;
            }

            return false;
        }

        protected IQueryable<CommentReaction> ApplyFilter(IQueryable<CommentReaction> query, CommentReactionSearchObject search)
        {
            if (search.UserId.HasValue)
                query = query.Where(b => b.UserId == search.UserId.Value);

            return query;
        }

        private CommentReactionResponse MapToResponse(CommentReaction reaction)
        {
            return new CommentReactionResponse
            {
                UserId = reaction.UserId,
                CommentId = reaction.CommentId,
                CommentAnswerId = reaction.CommentAnswerId,
                IsUpdated = false,
                IsLike = reaction.IsLike
            };
        }

    }
}
