using eKnjiga.Model.Requests;
using eKnjiga.Model.Responses;
using eKnjiga.Model.SearchObjects;
using eKnjiga.Services.Database;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using System;
using System.Linq;
using System.Threading.Tasks;

namespace eKnjiga.Services
{
    public class ReviewService : BaseCRUDService<ReviewResponse, ReviewSearchObject, Database.Review, ReviewUpsertRequest, ReviewUpsertRequest>, IReviewService
    {
        public ReviewService(eKnjigaDbContext context, IMapper mapper) : base(context, mapper) {}

        protected override IQueryable<Review> ApplyFilter(IQueryable<Review> query, ReviewSearchObject search)
        {
            if (search.UserId.HasValue)
                query = query.Where(b => b.UserId == search.UserId.Value);

            if (search.BookId.HasValue)
                query = query.Where(b => b.BookId == search.BookId.Value);

            if (search.Rating.HasValue)
                query = query.Where(b => b.Rating == search.Rating.Value);
                
            return query;
        }

        public override async Task<PagedResult<ReviewResponse>> GetAsync(ReviewSearchObject search)
        {
            var query = _context.Reviews
                .Include(r => r.Book)
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
                .Include(r => r.User)
                    .ThenInclude(c => c.City)
                        .ThenInclude(cc => cc.Country)
                .Include(r => r.User)
                    .ThenInclude(ur => ur.Role)
                .FirstOrDefaultAsync(r => r.Id == id);

            return review != null ? MapToResponse(review) : null;
        }

        private ReviewResponse MapToResponse(Database.Review review)
        {
            return new ReviewResponse
            {
                Id = review.Id,
                Rating = review.Rating,
                CreatedAt = review.CreatedAt,

                User = review.User != null ? new UserResponse
                {
                    Id = review.User.Id,
                    FirstName = review.User.FirstName,
                    LastName = review.User.LastName,
                    Email = review.User.Email,
                    Username = review.User.Username,
                    PhoneNumber = review.User.PhoneNumber,
                    CreatedAt = review.User.CreatedAt,
                    BirthDate = review.User.BirthDate,
                    Gender = review.User.Gender,
                    Role = review.User.Role != null ? new RoleResponse
                    {
                        Id = review.User.Role.Id,
                        Name = review.User.Role.Name,
                        Description = review.User.Role.Description
                    } : null,
                    City = review.User.City != null ? new CityResponse
                    {
                        Id = review.User.City.Id,
                        Name = review.User.City.Name,
                        Country = review.User.City.Country != null ? new CountryResponse
                        {
                            Id = review.User.City.Country.Id,
                            Name = review.User.City.Country.Name,
                            Code = review.User.City.Country.Code
                        } : null
                    } : null
                } : null,

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
            var entity = _mapper.Map<Review>(request);
            _context.Reviews.Add(entity);
            await _context.SaveChangesAsync();

            await UpdateBookRatingAsync(entity.BookId);

            var loaded = await _context.Reviews
                .Include(r => r.Book)
                .Include(r => r.User)
                    .ThenInclude(c => c.City)
                        .ThenInclude(cc => cc.Country)
                .Include(r => r.User)
                    .ThenInclude(ur => ur.Role)
                .FirstAsync(r => r.Id == entity.Id);

            return MapToResponse(loaded);
        }

        public override async Task<ReviewResponse?> UpdateAsync(int id, ReviewUpsertRequest request)
        {
            var entity = await _context.Reviews.FirstOrDefaultAsync(r => r.Id == id);
            if (entity == null)
                return null;

            var oldBookId = entity.BookId;
            _mapper.Map(request, entity);

            await _context.SaveChangesAsync();

            await UpdateBookRatingAsync(entity.BookId);
            if (oldBookId != entity.BookId)
            {
                await UpdateBookRatingAsync(oldBookId);
            }

            var loaded = await _context.Reviews
                .Include(r => r.Book)
                .Include(r => r.User)
                    .ThenInclude(c => c.City)
                        .ThenInclude(cc => cc.Country)
                .Include(r => r.User)
                    .ThenInclude(ur => ur.Role)
                .FirstAsync(r => r.Id == entity.Id);

            return MapToResponse(loaded);
        }

    }
}
