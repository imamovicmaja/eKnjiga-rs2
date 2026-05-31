using eKnjiga.Model;
using eKnjiga.Model.Enums;
using eKnjiga.Model.Requests;
using eKnjiga.Model.Responses;
using eKnjiga.Model.SearchObjects;
using eKnjiga.Services.Database;
using MapsterMapper;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Claims;
using System.Threading.Tasks;

namespace eKnjiga.Services
{
    public class ReviewService : BaseCRUDService<ReviewResponse, ReviewSearchObject, Database.Review, ReviewUpsertRequest, ReviewUpsertRequest>, IReviewService
    {
        private readonly IHttpContextAccessor _httpContextAccessor;

        public ReviewService(eKnjigaDbContext context, IMapper mapper, IHttpContextAccessor httpContextAccessor)
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

            return user.IsInRole("Admin") ||
                   user.Claims.Any(c =>
                       (c.Type == ClaimTypes.Role || c.Type == "role" || c.Type == "Role") &&
                       c.Value == "Admin");
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

        private void EnsureCanModifyReview(Database.Review review)
        {
            if (IsAdmin())
                return;

            var currentUserId = GetCurrentUserId();

            if (!currentUserId.HasValue)
                throw new UnauthorizedAccessException("User is not authenticated.");

            if (review.UserId != currentUserId.Value)
                throw new UnauthorizedAccessException("You are not allowed to modify this review.");
        }

        protected override IQueryable<Review> ApplyFilter(IQueryable<Review> query, ReviewSearchObject search)
        {
            if (search.UserId.HasValue)
                query = query.Where(r => r.UserId == search.UserId.Value);

            if (search.BookId.HasValue)
                query = query.Where(r => r.BookId == search.BookId.Value);

            if (search.Rating.HasValue)
                query = query.Where(r => r.Rating == search.Rating.Value);

            return query;
        }

        public override async Task<PagedResult<ReviewResponse>> GetAsync(ReviewSearchObject search)
        {
            var query = _context.Reviews
                .Include(r => r.Book)
                    .ThenInclude(b => b.BookAuthors)
                        .ThenInclude(ba => ba.Author)
                .Include(r => r.Book)
                    .ThenInclude(b => b.BookCategories)
                        .ThenInclude(bc => bc.Category)
                .Include(r => r.User)
                    .ThenInclude(c => c.City)
                        .ThenInclude(cc => cc.Country)
                .Include(r => r.User)
                    .ThenInclude(ur => ur.Role)
                .AsQueryable();

            query = ApplyFilter(query, search);

            int? totalCount = null;
            if (search.IncludeTotalCount)
            {
                totalCount = await query.CountAsync();
            }

            if (!search.RetrieveAll)
            {
                if (search.Page.HasValue)
                {
                    query = query.Skip(search.Page.Value * search.PageSize.Value);
                }

                if (search.PageSize.HasValue)
                {
                    query = query.Take(search.PageSize.Value);
                }
            }

            var list = await query.ToListAsync();

            return new PagedResult<ReviewResponse>
            {
                Items = list.Select(MapToResponse).ToList(),
                TotalCount = totalCount
            };
        }

        public override async Task<ReviewResponse?> GetByIdAsync(int id)
        {
            var review = await _context.Reviews
                .Include(r => r.Book)
                    .ThenInclude(b => b.BookAuthors)
                        .ThenInclude(ba => ba.Author)
                .Include(r => r.Book)
                    .ThenInclude(b => b.BookCategories)
                        .ThenInclude(bc => bc.Category)
                .Include(r => r.User)
                    .ThenInclude(c => c.City)
                        .ThenInclude(cc => cc.Country)
                .Include(r => r.User)
                    .ThenInclude(ur => ur.Role)
                .FirstOrDefaultAsync(r => r.Id == id);

            if (review == null)
                throw new KeyNotFoundException("Review not found.");

            return MapToResponse(review);
        }

        protected override async Task BeforeInsert(Review entity, ReviewUpsertRequest request)
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

        protected override async Task BeforeUpdate(Review entity, ReviewUpsertRequest request)
        {
            EnsureUserAuthenticated();
            EnsureCanModifyReview(entity);

            if (!IsAdmin())
            {
                var currentUserId = GetCurrentUserId()!.Value;
                entity.UserId = currentUserId;
                request.UserId = currentUserId;
            }

            await Task.CompletedTask;
        }

        private ReviewResponse MapToResponse(Database.Review review)
        {
            return new ReviewResponse
            {
                Id = review.Id,
                Rating = review.Rating,
                CreatedAt = review.CreatedAt,

                User = MapToPublicUserResponse(review.User),

                Book = review.Book != null ? new BookResponse
                {
                    Id = review.Book.Id,
                    Name = review.Book.Name,
                    Description = review.Book.Description,
                    Price = review.Book.Price,
                    Rating = review.Book.Rating,
                    RatingCount = review.Book.RatingCount,
                    CreatedAt = review.Book.CreatedAt,
                    Authors = review.Book.BookAuthors?.Select(ba => new AuthorResponse
                    {
                        Id = ba.Author.Id,
                        FirstName = ba.Author.FirstName,
                        LastName = ba.Author.LastName
                    }).ToList() ?? new List<AuthorResponse>(),
                    Categories = review.Book.BookCategories?.Select(bc => new CategoryResponse
                    {
                        Id = bc.Category.Id,
                        Name = bc.Category.Name
                    }).ToList() ?? new List<CategoryResponse>()
                } : null
            };
        }

        private async Task UpdateBookRatingAsync(int bookId)
        {
            var book = await _context.Books.FirstOrDefaultAsync(b => b.Id == bookId);
            if (book == null)
                return;

            var reviews = await _context.Reviews
                .Where(r => r.BookId == bookId)
                .ToListAsync();

            if (reviews.Count == 0)
            {
                book.Rating = 0;
                book.RatingCount = 0;
            }
            else
            {
                book.RatingCount = reviews.Count;
                book.Rating = reviews.Average(r => r.Rating);
            }

            await _context.SaveChangesAsync();
        }

        public override async Task<ReviewResponse> CreateAsync(ReviewUpsertRequest request)
        {
            EnsureUserAuthenticated();

            var currentUserId = GetCurrentUserId();

            if (!currentUserId.HasValue)
                throw new UnauthorizedAccessException("User is not authenticated.");

            if (!IsAdmin())
            {
                request.UserId = currentUserId.Value;

                var hasPurchased = await _context.Orders
                    .AnyAsync(o =>
                        o.UserId == currentUserId.Value &&
                        o.PaymentStatus == PaymentStatus.Paid &&
                        o.OrderItems.Any(oi => oi.BookId == request.BookId));

                if (!hasPurchased)
                    throw new UnauthorizedAccessException("You can review only books you have purchased.");

                var alreadyReviewed = await _context.Reviews
                    .AnyAsync(r =>
                        r.UserId == currentUserId.Value &&
                        r.BookId == request.BookId);

                if (alreadyReviewed)
                    throw new InvalidOperationException("You have already reviewed this book.");
            }

            var entity = new Database.Review
            {
                UserId = request.UserId,
                BookId = request.BookId,
                Rating = request.Rating,
                CreatedAt = DateTime.UtcNow
            };

            _context.Reviews.Add(entity);
            await _context.SaveChangesAsync();

            await UpdateBookRatingAsync(request.BookId);

            var created = await _context.Reviews
                .Include(r => r.User)
                    .ThenInclude(u => u.City)
                        .ThenInclude(c => c.Country)
                .Include(r => r.User)
                    .ThenInclude(u => u.Role)
                .Include(r => r.Book)
                    .ThenInclude(b => b.BookAuthors)
                        .ThenInclude(ba => ba.Author)
                .Include(r => r.Book)
                    .ThenInclude(b => b.BookCategories)
                        .ThenInclude(bc => bc.Category)
                .FirstOrDefaultAsync(r => r.Id == entity.Id);

            if (created == null)
                throw new Exception("Created review could not be loaded.");

            return MapToResponse(created);
        }

        public override async Task<ReviewResponse?> UpdateAsync(int id, ReviewUpsertRequest request)
        {
            EnsureUserAuthenticated();

            var entity = await _context.Reviews.FirstOrDefaultAsync(r => r.Id == id);
            if (entity == null)
                throw new KeyNotFoundException("Review not found.");

            EnsureCanModifyReview(entity);

            var oldBookId = entity.BookId;

            if (!IsAdmin())
            {
                request.UserId = entity.UserId;
            }

            _mapper.Map(request, entity);

            if (!IsAdmin())
            {
                entity.UserId = GetCurrentUserId()!.Value;
            }

            await _context.SaveChangesAsync();

            await UpdateBookRatingAsync(entity.BookId);
            if (oldBookId != entity.BookId)
            {
                await UpdateBookRatingAsync(oldBookId);
            }

            var loaded = await _context.Reviews
                .Include(r => r.Book)
                    .ThenInclude(b => b.BookAuthors)
                        .ThenInclude(ba => ba.Author)
                .Include(r => r.Book)
                    .ThenInclude(b => b.BookCategories)
                        .ThenInclude(bc => bc.Category)
                .Include(r => r.User)
                    .ThenInclude(c => c.City)
                        .ThenInclude(cc => cc.Country)
                .Include(r => r.User)
                    .ThenInclude(ur => ur.Role)
                .FirstAsync(r => r.Id == entity.Id);

            return MapToResponse(loaded);
        }

        public override async Task<bool> DeleteAsync(int id)
        {
            EnsureUserAuthenticated();

            var entity = await _context.Reviews.FirstOrDefaultAsync(r => r.Id == id);
            if (entity == null)
                throw new KeyNotFoundException("Review not found.");

            EnsureCanModifyReview(entity);

            var bookId = entity.BookId;

            _context.Reviews.Remove(entity);
            await _context.SaveChangesAsync();

            await UpdateBookRatingAsync(bookId);

            return true;
        }
    }
}