using eKnjiga.Model;
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
    public class CommentService : BaseCRUDService<CommentResponse, CommentSearchObject, Database.Comment, CommentUpsertRequest, CommentUpsertRequest>, ICommentService
    {
        private readonly IHttpContextAccessor _httpContextAccessor;

        public CommentService(eKnjigaDbContext context, IMapper mapper, IHttpContextAccessor httpContextAccessor)
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

        private void EnsureCanModifyComment(Database.Comment comment)
        {
            if (IsAdmin())
                return;

            var currentUserId = GetCurrentUserId();

            if (!currentUserId.HasValue)
                throw new UnauthorizedAccessException("User is not authenticated.");

            if (comment.UserId != currentUserId.Value)
                throw new UnauthorizedAccessException("You are not allowed to modify this comment.");
        }

        protected override IQueryable<Comment> ApplyFilter(IQueryable<Comment> query, CommentSearchObject search)
        {
            if (!string.IsNullOrEmpty(search.Content))
                query = query.Where(c => c.Content.Contains(search.Content));

            if (search.UserId.HasValue)
                query = query.Where(c => c.UserId == search.UserId.Value);

            return query;
        }

        public override async Task<PagedResult<CommentResponse>> GetAsync(CommentSearchObject search)
        {
            search ??= new CommentSearchObject();

            var query = _context.Comments
                .Include(c => c.User)
                    .ThenInclude(u => u.Role)
                .Include(c => c.User)
                    .ThenInclude(u => u.City)
                        .ThenInclude(c => c.Country)
                .Include(c => c.Replies)
                    .ThenInclude(cu => cu.User)
                .Include(c => c.Replies)
                    .ThenInclude(cr => cr.Reactions)
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

            return new PagedResult<CommentResponse>
            {
                Items = list.Select(MapToResponse).ToList(),
                TotalCount = totalCount
            };
        }

        public override async Task<CommentResponse?> GetByIdAsync(int id)
        {
            var comment = await _context.Comments
                .Include(c => c.User)
                    .ThenInclude(u => u.Role)
                .Include(c => c.User)
                    .ThenInclude(u => u.City)
                        .ThenInclude(c => c.Country)
                .Include(c => c.Replies)
                    .ThenInclude(cr => cr.Reactions)
                .Include(c => c.Replies)
                    .ThenInclude(cu => cu.User)
                .Include(c => c.Reactions)
                .FirstOrDefaultAsync(c => c.Id == id);

            if (comment == null)
                throw new KeyNotFoundException("Comment not found.");

            return MapToResponse(comment);
        }

        protected override async Task BeforeInsert(Comment entity, CommentUpsertRequest request)
        {
            EnsureUserAuthenticated();

            var currentUserId = GetCurrentUserId()!.Value;

            entity.UserId = currentUserId;
            request.UserId = currentUserId;
            entity.CreatedAt = DateTime.UtcNow;

            await Task.CompletedTask;
        }

        protected override async Task BeforeUpdate(Comment entity, CommentUpsertRequest request)
        {
            EnsureUserAuthenticated();
            EnsureCanModifyComment(entity);

            var currentUserId = GetCurrentUserId()!.Value;

            entity.UserId = currentUserId;
            request.UserId = currentUserId;

            await Task.CompletedTask;
        }

        private CommentResponse MapToResponse(Database.Comment comment)
        {
            return new CommentResponse
            {
                Id = comment.Id,
                Content = comment.Content,
                CreatedAt = comment.CreatedAt,
                Likes = comment.Reactions.Count(r => r.IsLike),
                Dislikes = comment.Reactions.Count(r => !r.IsLike),

                Replies = comment.Replies?.OrderByDescending(ca => ca.CreatedAt).Select(ca => new CommentAnswerResponse
                {
                    Id = ca.Id,
                    Content = ca.Content,
                    CreatedAt = ca.CreatedAt,
                    Likes = ca.Reactions.Count(r => r.IsLike),
                    Dislikes = ca.Reactions.Count(r => !r.IsLike),
                    User = MapToPublicUserResponse(ca.User)
                }).ToList() ?? new List<CommentAnswerResponse>(),

                User = MapToPublicUserResponse(comment.User)
            };
        }
        public override async Task<bool> DeleteAsync(int id)
        {
            EnsureUserAuthenticated();

            var comment = await _context.Comments.FindAsync(id);
            if (comment == null)
                throw new KeyNotFoundException("Comment not found.");

            EnsureCanModifyComment(comment);

            var replies = _context.CommentAnswers
                .Where(a => a.ParentCommentId == id)
                .ToList();

            var replyIds = replies.Select(r => r.Id).ToList();

            var replyReactions = _context.CommentReactions
                .Where(r => r.CommentAnswerId != null && replyIds.Contains(r.CommentAnswerId.Value));
            _context.CommentReactions.RemoveRange(replyReactions);

            _context.CommentAnswers.RemoveRange(replies);

            var commentReactions = _context.CommentReactions
                .Where(r => r.CommentId == id);
            _context.CommentReactions.RemoveRange(commentReactions);

            _context.Comments.Remove(comment);

            await _context.SaveChangesAsync();
            return true;
        }
    }
}