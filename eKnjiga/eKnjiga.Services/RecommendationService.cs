using Microsoft.EntityFrameworkCore;
using System.Linq;
using System.Threading.Tasks;
using System.Collections.Generic;
using eKnjiga.Services.Database;
using MapsterMapper;
using eKnjiga.Model.Responses;
using System;

namespace eKnjiga.Services
{
    public class RecommendationService : IRecommendationService
    {
        private readonly eKnjigaDbContext _ctx;
        private readonly IMapper _mapper;

        public RecommendationService(eKnjigaDbContext ctx, IMapper mapper)
        {
            _ctx = ctx;
            _mapper = mapper;
        }

        private static BookResponse MapBookToResponse(Book b) => new BookResponse
        {
            Id = b.Id,
            Name = b.Name,
            Description = b.Description,
            Price = b.Price,
            CoverImage = b.CoverImage,
            PdfFile = b.PdfFile,
            Rating = b.Rating,
            RatingCount = b.RatingCount,
            CreatedAt = b.CreatedAt,
            Authors = b.BookAuthors?
                .Select(ba => new AuthorResponse
                {
                    Id = ba.Author.Id,
                    FirstName = ba.Author.FirstName,
                    LastName = ba.Author.LastName
                }).ToList() ?? new List<AuthorResponse>(),
            Categories = b.BookCategories?
                .Select(bc => new CategoryResponse
                {
                    Id = bc.Category.Id,
                    Name = bc.Category.Name
                }).ToList() ?? new List<CategoryResponse>()
        };

        public async Task<IReadOnlyList<BookResponse>> GetRecommendedAsync(int userId, int count = 10, int? categoryId = null)
        {
            var userBookIds = await _ctx.Orders
                .Where(o => o.UserId == userId)
                .SelectMany(o => o.OrderItems.Select(oi => oi.BookId))
                .Distinct()
                .ToListAsync();

            IQueryable<Book> baseQuery = _ctx.Books
                .Include(b => b.BookAuthors).ThenInclude(ba => ba.Author)
                .Include(b => b.BookCategories).ThenInclude(bc => bc.Category);

            if (categoryId.HasValue)
            {
                baseQuery = baseQuery.Where(b => b.BookCategories.Any(bc => bc.CategoryId == categoryId.Value));
            }

            if (userBookIds.Count == 0)
            {
                var coldBooks = await baseQuery
                    .AsNoTracking()
                    .OrderByDescending(b => (b.Rating * (b.RatingCount + 1)))
                    .ThenByDescending(b => b.CreatedAt)
                    .Take(count)
                    .ToListAsync();

                return coldBooks.Select(MapBookToResponse).ToList();
            }

            var userProfile = await _ctx.Books
                .Where(b => userBookIds.Contains(b.Id))
                .Select(b => new
                {
                    CatIds = b.BookCategories.Select(bc => bc.CategoryId),
                    AuthorIds = b.BookAuthors.Select(ba => ba.AuthorId)
                })
                .ToListAsync();

            var favCats = userProfile
                .SelectMany(x => x.CatIds)
                .GroupBy(x => x)
                .ToDictionary(g => g.Key, g => g.Count());

            var favAuthors = userProfile
                .SelectMany(x => x.AuthorIds)
                .GroupBy(x => x)
                .ToDictionary(g => g.Key, g => g.Count());

            var candidates = await baseQuery
                .Where(b => !userBookIds.Contains(b.Id))
                .ToListAsync();

            var scored = candidates
                .Select(b =>
                {
                    int score = 0;

                    foreach (var bc in b.BookCategories)
                        if (favCats.TryGetValue(bc.CategoryId, out var w1)) score += w1;

                    foreach (var ba in b.BookAuthors)
                        if (favAuthors.TryGetValue(ba.AuthorId, out var w2)) score += w2;

                    score += (int)Math.Round(b.Rating * 10);

                    return (Book: b, Score: score);
                })
                .OrderByDescending(x => x.Score)
                .ThenByDescending(x => x.Book.CreatedAt)
                .Take(count)
                .Select(x => MapBookToResponse(x.Book))
                .ToList();

            return scored;
        }

        public async Task<IReadOnlyList<BookResponse>> GetPersonalizedSimilarAsync(int userId, int bookId, int count = 10)
        {
            var target = await _ctx.Books
                .Include(b => b.BookCategories)
                .Include(b => b.BookAuthors)
                .FirstOrDefaultAsync(b => b.Id == bookId);

            if (target == null)
                return new List<BookResponse>();

            var targetCatIds = target.BookCategories.Select(bc => bc.CategoryId).ToHashSet();
            var targetAuthorIds = target.BookAuthors.Select(ba => ba.AuthorId).ToHashSet();

            var userBookIds = await _ctx.Orders
                .Where(o => o.UserId == userId)
                .SelectMany(o => o.OrderItems.Select(oi => oi.BookId))
                .Distinct()
                .ToListAsync();

            var favCats = new Dictionary<int, int>();
            var favAuthors = new Dictionary<int, int>();

            if (userBookIds.Count > 0)
            {
                var userProfile = await _ctx.Books
                    .Where(b => userBookIds.Contains(b.Id))
                    .Select(b => new
                    {
                        CatIds = b.BookCategories.Select(bc => bc.CategoryId),
                        AuthorIds = b.BookAuthors.Select(ba => ba.AuthorId)
                    })
                    .ToListAsync();

                favCats = userProfile.SelectMany(x => x.CatIds)
                                    .GroupBy(x => x)
                                    .ToDictionary(g => g.Key, g => g.Count());

                favAuthors = userProfile.SelectMany(x => x.AuthorIds)
                                        .GroupBy(x => x)
                                        .ToDictionary(g => g.Key, g => g.Count());
            }

            var candidates = await _ctx.Books
                .Where(b => b.Id != bookId && !userBookIds.Contains(b.Id))
                .Include(b => b.BookCategories)
                .Include(b => b.BookAuthors)
                .Include(b => b.BookAuthors).ThenInclude(ba => ba.Author)
                .Include(b => b.BookCategories).ThenInclude(bc => bc.Category)
                .ToListAsync();

            var scored = candidates
                .Select(b =>
                {
                    int score = 0;

                    foreach (var bc in b.BookCategories)
                        if (targetCatIds.Contains(bc.CategoryId)) score += 2;

                    foreach (var ba in b.BookAuthors)
                        if (targetAuthorIds.Contains(ba.AuthorId)) score += 3;

                    foreach (var bc in b.BookCategories)
                        if (favCats.TryGetValue(bc.CategoryId, out var w1)) score += w1;

                    foreach (var ba in b.BookAuthors)
                        if (favAuthors.TryGetValue(ba.AuthorId, out var w2)) score += w2;

                    score += (int)Math.Round(b.Rating * 10);

                    return (Book: b, Score: score);
                })
                .OrderByDescending(x => x.Score)
                .ThenByDescending(x => x.Book.CreatedAt)
                .Take(count)
                .Select(x => MapBookToResponse(x.Book))
                .ToList();

            return scored;
        }


        private BookResponse MapToResponse(Database.Book b)
            => _mapper.Map<BookResponse>(b);
    }
}
