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
            var cf = await GetRecommendedCfKnnAsync(userId, count, k: 25, categoryId);
            if (cf.Count > 0)
                return cf;

            return await GetRecommendedHeuristicAsync(userId, count, categoryId);
        }

        public async Task<IReadOnlyList<BookResponse>> GetRecommendedHeuristicAsync(int userId, int count = 10, int? categoryId = null)
        {
            var userBookIds = await _ctx.UserBooks
                .AsNoTracking()
                .Where(ub => ub.UserId == userId)
                .Select(ub => ub.BookId)
                .Distinct()
                .ToListAsync();

            var userBookSet = userBookIds.ToHashSet();

            IQueryable<Book> baseQuery = _ctx.Books
                .Include(b => b.BookAuthors).ThenInclude(ba => ba.Author)
                .Include(b => b.BookCategories).ThenInclude(bc => bc.Category);

            if (categoryId.HasValue)
            {
                baseQuery = baseQuery.Where(b => b.BookCategories.Any(bc => bc.CategoryId == categoryId.Value));
            }

            // Cold-start: no purchases -> best rated/newest
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

            // Build user profile from purchases (categories & authors)
            var userProfile = await _ctx.Books
                .AsNoTracking()
                .Where(b => userBookSet.Contains(b.Id))
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

            // ✅ KLJUČNO: filtriraj kupljene u query-ju (prije ToListAsync)
            var candidates = await baseQuery
                .AsNoTracking()
                .Where(b => !userBookSet.Contains(b.Id))
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

            scored = scored.Where(x => !userBookSet.Contains(x.Id)).ToList();

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

        public async Task<IReadOnlyList<BookResponse>> GetRecommendedCfKnnAsync(
            int userId,
            int count = 10,
            int k = 25,
            int? categoryId = null)
        {
            var targetRatingsList = await _ctx.Reviews
                .AsNoTracking()
                .Where(r => r.UserId == userId)
                .Select(r => new { r.BookId, r.Rating })
                .ToListAsync();

            if (targetRatingsList.Count == 0)
                return new List<BookResponse>();

            var targetRatings = targetRatingsList.ToDictionary(x => x.BookId, x => x.Rating);
            var targetBookIds = targetRatings.Keys.ToHashSet();

            var normU = Math.Sqrt(targetRatings.Values.Sum(v => v * v));
            if (normU == 0)
                return new List<BookResponse>();

            // 2) Other users' reviews on the same books (overlap)
            var overlap = await _ctx.Reviews
                .AsNoTracking()
                .Where(r => r.UserId != userId && targetBookIds.Contains(r.BookId))
                .Select(r => new { r.UserId, r.BookId, r.Rating })
                .ToListAsync();

            if (overlap.Count == 0)
                return new List<BookResponse>();

            // 3) Cosine similarity per neighbor
            var dot = new Dictionary<int, double>();
            var normV2 = new Dictionary<int, double>();

            foreach (var r in overlap)
            {
                var uRating = targetRatings[r.BookId];

                if (!dot.ContainsKey(r.UserId)) dot[r.UserId] = 0;
                if (!normV2.ContainsKey(r.UserId)) normV2[r.UserId] = 0;

                dot[r.UserId] += uRating * r.Rating;
                normV2[r.UserId] += r.Rating * r.Rating;
            }

            var sims = dot
                .Select(kv =>
                {
                    var v = kv.Key;
                    var denom = normU * Math.Sqrt(normV2[v]);
                    var sim = denom == 0 ? 0 : kv.Value / denom;
                    return new { UserId = v, Sim = sim };
                })
                .Where(x => x.Sim > 0)
                .OrderByDescending(x => x.Sim)
                .Take(k)
                .ToList();

            if (sims.Count == 0)
                return new List<BookResponse>();

            var neighborIds = sims.Select(x => x.UserId).ToList();
            var simByUser = sims.ToDictionary(x => x.UserId, x => x.Sim);


            // 4) Candidate books: rated by neighbors, not rated by target,
            //    and NOT already owned by target (UserBooks)
            var neighborReviewsQuery = _ctx.Reviews
                .AsNoTracking()
                .Where(r =>
                    neighborIds.Contains(r.UserId) &&
                    !targetBookIds.Contains(r.BookId) &&
                    !_ctx.UserBooks.Any(ub => ub.UserId == userId && ub.BookId == r.BookId));

            if (categoryId.HasValue)
            {
                neighborReviewsQuery = neighborReviewsQuery.Where(r =>
                    _ctx.BookCategories.Any(bc => bc.BookId == r.BookId && bc.CategoryId == categoryId.Value));
            }

            var neighborReviews = await neighborReviewsQuery
                .Select(r => new { r.BookId, r.UserId, r.Rating })
                .ToListAsync();


            if (neighborReviews.Count == 0)
                return new List<BookResponse>();

            // 5) Weighted prediction per book
            var num = new Dictionary<int, double>();
            var den = new Dictionary<int, double>();

            foreach (var r in neighborReviews)
            {
                var sim = simByUser[r.UserId];

                if (!num.ContainsKey(r.BookId)) num[r.BookId] = 0;
                if (!den.ContainsKey(r.BookId)) den[r.BookId] = 0;

                num[r.BookId] += sim * r.Rating;
                den[r.BookId] += Math.Abs(sim);
            }

            var predicted = num
                .Select(kv =>
                {
                    var bookId = kv.Key;
                    var d = den[bookId];
                    var score = d == 0 ? 0 : kv.Value / d;
                    return new { BookId = bookId, Score = score };
                })
                .Where(x => x.Score > 0)
                .OrderByDescending(x => x.Score)
                .Take(count * 3)
                .ToList();

            if (predicted.Count == 0)
                return new List<BookResponse>();

            var predictedIds = predicted.Select(x => x.BookId).ToList();
            var scoreByBook = predicted.ToDictionary(x => x.BookId, x => x.Score);

            // 6) Load books and return top-N by predicted score
            var books = await _ctx.Books
                .Include(b => b.BookAuthors).ThenInclude(ba => ba.Author)
                .Include(b => b.BookCategories).ThenInclude(bc => bc.Category)
                .AsNoTracking()
                .Where(b => predictedIds.Contains(b.Id))
                .ToListAsync();

            var ordered = books
                .Select(b => new { Book = b, Score = scoreByBook.GetValueOrDefault(b.Id, 0) })
                .OrderByDescending(x => x.Score)
                .ThenByDescending(x => x.Book.CreatedAt)
                .Take(count)
                .Select(x => MapBookToResponse(x.Book))
                .ToList();

            return ordered;
        }

        private BookResponse MapToResponse(Database.Book b)
            => _mapper.Map<BookResponse>(b);
    }
}