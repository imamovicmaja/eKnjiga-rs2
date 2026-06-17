using eKnjiga.Model.Requests;
using eKnjiga.Model.Responses;
using eKnjiga.Model.SearchObjects;
using eKnjiga.Model.Constants;
using eKnjiga.Services.Database;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;

using System.Security.Claims;


namespace eKnjiga.Services
{
    public class CommentReactionService : ICommentReactionService
    {
        private readonly eKnjigaDbContext _context;
        private readonly IHttpContextAccessor _httpContextAccessor;

        public CommentReactionService(eKnjigaDbContext context, IHttpContextAccessor httpContextAccessor)
        {
            _context = context;
            _httpContextAccessor = httpContextAccessor;
        }

        private int? GetCurrentUserId()
        {
            var user = _httpContextAccessor.HttpContext?.User;

            var userIdClaim =
                user?.FindFirst(ClaimTypes.NameIdentifier)?.Value ??
                user?.FindFirst("UserId")?.Value ??
                user?.FindFirst("Id")?.Value;

            if (int.TryParse(userIdClaim, out var userId))
                return userId;

            return null;
        }

        private bool IsAdmin()
        {
            var user = _httpContextAccessor.HttpContext?.User;

            if (user == null)
                return false;

            return user.IsInRole(RoleNames.Admin) ||
                   user.Claims.Any(c =>
                       (c.Type == ClaimTypes.Role || c.Type == "role" || c.Type == "Role") &&
                       c.Value == RoleNames.Admin);
        }

        private void EnsureUserAuthenticated()
        {
            if (!GetCurrentUserId().HasValue)
                throw new UnauthorizedAccessException("User is not authenticated.");
        }

        private int ResolveUserId()
        {
            EnsureUserAuthenticated();
            return GetCurrentUserId()!.Value;
        }

        public async Task<PagedResult<CommentReactionResponse>> GetAsync(CommentReactionSearchObject search)
        {
            search ??= new CommentReactionSearchObject();

            var query = _context.CommentReactions.AsQueryable();

            query = ApplyFilter(query, search);

            query = query.OrderBy(r => r.UserId)
                         .ThenBy(r => r.CommentId)
                         .ThenBy(r => r.CommentAnswerId);

            var page = search.Page < 1 ? 1 : search.Page;
            var pageSize = search.PageSize < 1 ? 10 : search.PageSize;

            int? totalCount = null;

            if (search.IncludeTotalCount)
            {
                totalCount = await query.CountAsync();
            }

            query = query
                .Skip((page - 1) * pageSize)
                .Take(pageSize);

            var list = await query.ToListAsync();

            return new PagedResult<CommentReactionResponse>
            {
                Items = list.Select(MapToResponse).ToList(),
                TotalCount = totalCount
            };
        }

        public async Task<CommentReactionResponse> CreateOrUpdateReactionAsync(CommentReactionRequest request)
        {
            EnsureUserAuthenticated();

            if ((request.CommentId == null && request.CommentAnswerId == null) ||
                (request.CommentId != null && request.CommentAnswerId != null))
            {
                throw new ArgumentException("Potrebno je navesti tačno jedan od CommentId ili CommentAnswerId.");
            }

            var resolvedUserId = ResolveUserId();

            var existing = await _context.CommentReactions
                .FirstOrDefaultAsync(r =>
                    r.UserId == resolvedUserId &&
                    r.CommentId == request.CommentId &&
                    r.CommentAnswerId == request.CommentAnswerId);

            if (existing != null)
            {
                existing.IsLike = request.IsLike;
                await _context.SaveChangesAsync();

                return new CommentReactionResponse
                {
                    UserId = resolvedUserId,
                    CommentId = request.CommentId,
                    CommentAnswerId = request.CommentAnswerId,
                    IsUpdated = true,
                    IsLike = request.IsLike
                };
            }
            else
            {
                var newReaction = new CommentReaction
                {
                    UserId = resolvedUserId,
                    CommentId = request.CommentId,
                    CommentAnswerId = request.CommentAnswerId,
                    IsLike = request.IsLike
                };

                _context.CommentReactions.Add(newReaction);
                await _context.SaveChangesAsync();

                return new CommentReactionResponse
                {
                    UserId = resolvedUserId,
                    CommentId = request.CommentId,
                    CommentAnswerId = request.CommentAnswerId,
                    IsUpdated = false,
                    IsLike = request.IsLike
                };
            }
        }

        public async Task<bool> RemoveReactionAsync(CommentReactionRequest request)
        {
            EnsureUserAuthenticated();

            if ((request.CommentId == null && request.CommentAnswerId == null) ||
                (request.CommentId != null && request.CommentAnswerId != null))
            {
                throw new ArgumentException("Potrebno je navesti tačno jedan od CommentId ili CommentAnswerId.");
            }

            var resolvedUserId = ResolveUserId();

            var existing = await _context.CommentReactions
                .FirstOrDefaultAsync(r =>
                    r.UserId == resolvedUserId &&
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
                query = query.Where(r => r.UserId == search.UserId.Value);

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