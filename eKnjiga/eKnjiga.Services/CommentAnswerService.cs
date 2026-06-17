using eKnjiga.Model.Requests;
using eKnjiga.Model.Responses;
using eKnjiga.Model.SearchObjects;
using eKnjiga.Services.Database;
using eKnjiga.Model.Constants;
using MapsterMapper;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace eKnjiga.Services
{
    public class CommentAnswerService : BaseCRUDService<CommentAnswerResponse, CommentAnswerSearchObject, Database.CommentAnswer, CommentAnswerUpsertRequest, CommentAnswerUpsertRequest>, ICommentAnswerService
    {
        private readonly IHttpContextAccessor _httpContextAccessor;

        public CommentAnswerService(eKnjigaDbContext context, IMapper mapper, IHttpContextAccessor httpContextAccessor)
            : base(context, mapper)
        {
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

        private PublicUserResponse? MapToPublicUserResponse(Database.User? user)
        {
            if (user == null)
                return null;

            return new PublicUserResponse
            {
                Id = user.Id,
                Username = user.Username,
                FirstName = user.FirstName,
                LastName = user.LastName,
                ProfileImage = string.IsNullOrEmpty(user.ProfileImage)
                ? "/images/default-user.jpg"
                : user.ProfileImage
            };
        }

        private void EnsureUserAuthenticated()
        {
            if (!GetCurrentUserId().HasValue)
                throw new UnauthorizedAccessException("User is not authenticated.");
        }

        private void EnsureCanModifyCommentAnswer(Database.CommentAnswer commentAnswer)
        {
            if (IsAdmin())
                return;

            var currentUserId = GetCurrentUserId();

            if (!currentUserId.HasValue)
                throw new UnauthorizedAccessException("User is not authenticated.");

            if (commentAnswer.UserId != currentUserId.Value)
                throw new UnauthorizedAccessException("You are not allowed to modify this reply.");
        }

        protected override IQueryable<CommentAnswer> ApplyFilter(IQueryable<CommentAnswer> query, CommentAnswerSearchObject search)
        {
            if (!string.IsNullOrEmpty(search.Content))
                query = query.Where(c => c.Content.Contains(search.Content));

            if (search.UserId.HasValue)
                query = query.Where(c => c.UserId == search.UserId.Value);

            if (search.ParentCommentId.HasValue)
                query = query.Where(c => c.ParentCommentId == search.ParentCommentId.Value);

            return query;
        }

        public override async Task<PagedResult<CommentAnswerResponse>> GetAsync(CommentAnswerSearchObject search)
        {
            search ??= new CommentAnswerSearchObject();

            var query = _context.CommentAnswers
                .Include(c => c.User)
                    .ThenInclude(u => u.Role)
                .Include(c => c.User)
                    .ThenInclude(u => u.City)
                        .ThenInclude(cc => cc.Country)
                .Include(c => c.ParentComment)
                    .ThenInclude(pc => pc.User)
                .Include(c => c.ParentComment)
                    .ThenInclude(pc => pc.Reactions)
                .Include(c => c.Reactions)
                .AsQueryable();

            query = ApplyFilter(query, search);

            query = query.OrderByDescending(c => c.CreatedAt);

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

            return new PagedResult<CommentAnswerResponse>
            {
                Items = list.Select(MapToResponse).ToList(),
                TotalCount = totalCount
            };
        }

        public override async Task<CommentAnswerResponse?> GetByIdAsync(int id)
        {
            var comment = await _context.CommentAnswers
                .Include(c => c.User)
                    .ThenInclude(u => u.Role)
                .Include(c => c.User)
                    .ThenInclude(u => u.City)
                        .ThenInclude(cc => cc.Country)
                .Include(c => c.ParentComment)
                    .ThenInclude(pc => pc.User)
                .Include(c => c.ParentComment)
                    .ThenInclude(pc => pc.Reactions)
                .Include(c => c.Reactions)
                .FirstOrDefaultAsync(c => c.Id == id);

            if (comment == null)
                throw new KeyNotFoundException("Comment reply not found.");

            return MapToResponse(comment);
        }

        protected override async Task BeforeInsert(CommentAnswer entity, CommentAnswerUpsertRequest request)
        {
            EnsureUserAuthenticated();

            if (!IsAdmin())
            {
                var currentUserId = GetCurrentUserId()!.Value;
                entity.UserId = currentUserId;
                request.UserId = currentUserId;
            }

            await Task.CompletedTask;
        }

        protected override async Task BeforeUpdate(CommentAnswer entity, CommentAnswerUpsertRequest request)
        {
            EnsureUserAuthenticated();
            EnsureCanModifyCommentAnswer(entity);

            if (!IsAdmin())
            {
                var currentUserId = GetCurrentUserId()!.Value;
                entity.UserId = currentUserId;
                request.UserId = currentUserId;
            }

            await Task.CompletedTask;
        }

        private CommentAnswerResponse MapToResponse(Database.CommentAnswer comment)
        {
            return new CommentAnswerResponse
            {
                Id = comment.Id,
                Content = comment.Content,
                CreatedAt = comment.CreatedAt,
                Likes = comment.Reactions.Count(r => r.IsLike),
                Dislikes = comment.Reactions.Count(r => !r.IsLike),

                ParentComment = comment.ParentComment != null ? new CommentResponse
                {
                    Id = comment.ParentComment.Id,
                    Content = comment.ParentComment.Content,
                    CreatedAt = comment.ParentComment.CreatedAt,
                    Likes = comment.ParentComment.Reactions.Count(r => r.IsLike),
                    Dislikes = comment.ParentComment.Reactions.Count(r => !r.IsLike),
                    User = MapToPublicUserResponse(comment.ParentComment.User)
                } : null,

                User = MapToPublicUserResponse(comment.User)
            };
        }

        public override async Task<bool> DeleteAsync(int id)
        {
            EnsureUserAuthenticated();

            var entity = await _context.CommentAnswers.FindAsync(id);
            if (entity == null)
                throw new KeyNotFoundException("Comment reply not found.");

            EnsureCanModifyCommentAnswer(entity);

            var reactions = _context.CommentReactions
                .Where(r => r.CommentAnswerId == id);

            _context.CommentReactions.RemoveRange(reactions);
            _context.CommentAnswers.Remove(entity);

            await _context.SaveChangesAsync();
            return true;
        }
    }
}