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

        private static BookListResponse MapBookToResponse(Book b, string? whyRecommended = null) => new BookListResponse
        {
            Id = b.Id,
            Name = b.Name,
            Rating = b.Rating,
            RatingCount = b.RatingCount,
            CoverImage = b.CoverImage,
            WhyRecommended = whyRecommended,
            Authors = b.BookAuthors?
                .Select(ba => new AuthorResponse
                {
                    Id = ba.Author.Id,
                    FirstName = ba.Author.FirstName,
                    LastName = ba.Author.LastName
                })
                .ToList() ?? new List<AuthorResponse>()
        };

        public async Task<IReadOnlyList<BookListResponse>> GetRecommendedAsync(int userId, int count = 10, int? categoryId = null)
        {
            var cf = await GetRecommendedCfKnnAsync(userId, count, 25, categoryId);

            if (cf.Count > 0)
                return cf;

            return await GetRecommendedHeuristicAsync(userId, count, categoryId);
        }

        public async Task<IReadOnlyList<BookListResponse>> GetRecommendedHeuristicAsync(int userId, int count = 10, int? categoryId = null)
        {
            var userBookIds = await _ctx.UserBooks
                .AsNoTracking()
                .Where(ub => ub.UserId == userId)
                .Select(ub => ub.BookId)
                .Distinct()
                .ToListAsync();

            var userBookSet = userBookIds.ToHashSet();

            IQueryable<Book> baseQuery = _ctx.Books.AsQueryable();

            if (categoryId.HasValue)
            {
                baseQuery = baseQuery.Where(b =>
                    b.BookCategories.Any(bc => bc.CategoryId == categoryId.Value));
            }

            if (userBookIds.Count == 0)
            {
                return await baseQuery
                    .AsNoTracking()
                    .OrderByDescending(b => b.Rating * (b.RatingCount + 1))
                    .ThenByDescending(b => b.CreatedAt)
                    .Take(count)
                    .Select(b => new BookListResponse
                    {
                        Id = b.Id,
                        Name = b.Name,
                        Rating = b.Rating,
                        RatingCount = b.RatingCount,
                        CoverImage = b.CoverImage,
                        WhyRecommended = "Preporučeno jer je popularno među korisnicima.",
                        Authors = b.BookAuthors.Select(ba => new AuthorResponse
                        {
                            Id = ba.Author.Id,
                            FirstName = ba.Author.FirstName,
                            LastName = ba.Author.LastName
                        }).ToList()
                    })
                    .ToListAsync();
            }

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

            var candidates = await baseQuery
                .AsNoTracking()
                .Where(b => !userBookSet.Contains(b.Id))
                .Select(b => new
                {
                    Id = b.Id,
                    Name = b.Name,
                    Rating = b.Rating,
                    RatingCount = b.RatingCount,
                    CoverImage = b.CoverImage,
                    CreatedAt = b.CreatedAt,
                    CategoryIds = b.BookCategories.Select(bc => bc.CategoryId).ToList(),
                    AuthorIds = b.BookAuthors.Select(ba => ba.AuthorId).ToList(),
                    Authors = b.BookAuthors.Select(ba => new AuthorResponse
                    {
                        Id = ba.Author.Id,
                        FirstName = ba.Author.FirstName,
                        LastName = ba.Author.LastName
                    }).ToList()
                })
                .ToListAsync();

            var scored = candidates
                .Select(b =>
                {
                    int score = 0;
                    bool matchedCategory = false;
                    bool matchedAuthor = false;

                    foreach (var catId in b.CategoryIds)
                    {
                        if (favCats.TryGetValue(catId, out var w1))
                        {
                            score += w1;
                            matchedCategory = true;
                        }
                    }

                    foreach (var authorId in b.AuthorIds)
                    {
                        if (favAuthors.TryGetValue(authorId, out var w2))
                        {
                            score += w2;
                            matchedAuthor = true;
                        }
                    }

                    if (!matchedAuthor && !matchedCategory)
                    {
                        score = 0;
                    }
                    else
                    {
                        score += (int)Math.Round(b.Rating * 10);
                    }

                    string whyRecommended;

                    if (matchedAuthor)
                    {
                        whyRecommended = "Preporučeno jer često čitate knjige istih ili sličnih autora.";
                    }
                    else if (matchedCategory)
                    {
                        whyRecommended = "Preporučeno jer ste kupili knjige iz iste kategorije.";
                    }
                    else
                    {
                        whyRecommended = "";
                    }

                    return new
                    {
                        Book = new BookListResponse
                        {
                            Id = b.Id,
                            Name = b.Name,
                            Rating = b.Rating,
                            RatingCount = b.RatingCount,
                            CoverImage = b.CoverImage,
                            Authors = b.Authors,
                            WhyRecommended = whyRecommended
                        },
                        Score = score,
                        CreatedAt = b.CreatedAt
                    };
                })
                .Where(x => x.Score > 0)
                .OrderByDescending(x => x.Score)
                .ThenByDescending(x => x.CreatedAt)
                .Take(count)
                .Select(x => x.Book)
                .ToList();

            return scored;
        }

        public async Task<IReadOnlyList<BookListResponse>> GetPersonalizedSimilarAsync(int userId, int bookId, int count = 10)
        {
            var target = await _ctx.Books
                .AsNoTracking()
                .Where(b => b.Id == bookId)
                .Select(b => new
                {
                    CategoryIds = b.BookCategories.Select(bc => bc.CategoryId).ToList(),
                    AuthorIds = b.BookAuthors.Select(ba => ba.AuthorId).ToList()
                })
                .FirstOrDefaultAsync();

            if (target == null)
                return new List<BookListResponse>();

            var targetCatIds = target.CategoryIds.ToHashSet();
            var targetAuthorIds = target.AuthorIds.ToHashSet();

            var userBookIds = await _ctx.UserBooks
                .AsNoTracking()
                .Where(ub => ub.UserId == userId)
                .Select(ub => ub.BookId)
                .Distinct()
                .ToListAsync();

            var favCats = new Dictionary<int, int>();
            var favAuthors = new Dictionary<int, int>();

            if (userBookIds.Count > 0)
            {
                var userProfile = await _ctx.Books
                    .AsNoTracking()
                    .Where(b => userBookIds.Contains(b.Id))
                    .Select(b => new
                    {
                        CatIds = b.BookCategories.Select(bc => bc.CategoryId),
                        AuthorIds = b.BookAuthors.Select(ba => ba.AuthorId)
                    })
                    .ToListAsync();

                favCats = userProfile
                    .SelectMany(x => x.CatIds)
                    .GroupBy(x => x)
                    .ToDictionary(g => g.Key, g => g.Count());

                favAuthors = userProfile
                    .SelectMany(x => x.AuthorIds)
                    .GroupBy(x => x)
                    .ToDictionary(g => g.Key, g => g.Count());
            }

            var candidates = await _ctx.Books
                .AsNoTracking()
                .Where(b => b.Id != bookId && !userBookIds.Contains(b.Id))
                .Select(b => new
                {
                    Id = b.Id,
                    Name = b.Name,
                    Rating = b.Rating,
                    RatingCount = b.RatingCount,
                    CoverImage = b.CoverImage,
                    CreatedAt = b.CreatedAt,
                    CategoryIds = b.BookCategories.Select(bc => bc.CategoryId).ToList(),
                    AuthorIds = b.BookAuthors.Select(ba => ba.AuthorId).ToList(),
                    Authors = b.BookAuthors.Select(ba => new AuthorResponse
                    {
                        Id = ba.Author.Id,
                        FirstName = ba.Author.FirstName,
                        LastName = ba.Author.LastName
                    }).ToList()
                })
                .ToListAsync();

            var scored = candidates
                .Select(b =>
                {
                    int score = 0;

                    var sameTargetCategory = false;
                    var sameTargetAuthor = false;
                    var matchedUserCategory = false;
                    var matchedUserAuthor = false;

                    foreach (var catId in b.CategoryIds)
                    {
                        if (targetCatIds.Contains(catId))
                        {
                            score += 2;
                            sameTargetCategory = true;
                        }

                        if (favCats.TryGetValue(catId, out var w1))
                        {
                            score += w1;
                            matchedUserCategory = true;
                        }
                    }

                    foreach (var authorId in b.AuthorIds)
                    {
                        if (targetAuthorIds.Contains(authorId))
                        {
                            score += 3;
                            sameTargetAuthor = true;
                        }

                        if (favAuthors.TryGetValue(authorId, out var w2))
                        {
                            score += w2;
                            matchedUserAuthor = true;
                        }
                    }

                    score += (int)Math.Round(b.Rating * 10);

                    string whyRecommended;

                    if (sameTargetAuthor)
                    {
                        whyRecommended = "Preporučeno jer je knjiga od istog ili sličnog autora.";
                    }
                    else if (sameTargetCategory)
                    {
                        whyRecommended = "Preporučeno jer je iz iste kategorije kao knjiga koju gledate.";
                    }
                    else if (matchedUserAuthor)
                    {
                        whyRecommended = "Preporučeno jer često čitate knjige istih ili sličnih autora.";
                    }
                    else if (matchedUserCategory)
                    {
                        whyRecommended = "Preporučeno jer ste kupili knjige iz iste kategorije.";
                    }
                    else
                    {
                        whyRecommended = "Preporučeno na osnovu sličnosti sa knjigama koje čitate.";
                    }

                    return new
                    {
                        Book = new BookListResponse
                        {
                            Id = b.Id,
                            Name = b.Name,
                            Rating = b.Rating,
                            RatingCount = b.RatingCount,
                            CoverImage = b.CoverImage,
                            Authors = b.Authors,
                            WhyRecommended = whyRecommended
                        },
                        Score = score,
                        CreatedAt = b.CreatedAt
                    };
                })
                .Where(x => x.Score > 0)
                .OrderByDescending(x => x.Score)
                .ThenByDescending(x => x.CreatedAt)
                .Take(count)
                .Select(x => x.Book)
                .ToList();

            return scored;
        }

        public async Task<IReadOnlyList<BookListResponse>> GetRecommendedCfKnnAsync(
            int userId,
            int count = 10,
            int k = 25,
            int? categoryId = null)
        {
            var ownedBookIds = await _ctx.UserBooks
                .AsNoTracking()
                .Where(ub => ub.UserId == userId)
                .Select(ub => ub.BookId)
                .Distinct()
                .ToListAsync();

            var ownedBookSet = ownedBookIds.ToHashSet();

            var targetRatingsList = await _ctx.Reviews
                .AsNoTracking()
                .Where(r => r.UserId == userId && ownedBookSet.Contains(r.BookId))
                .Select(r => new { r.BookId, r.Rating })
                .ToListAsync();

            if (targetRatingsList.Count == 0)
                return new List<BookListResponse>();

            var targetRatings = targetRatingsList.ToDictionary(x => x.BookId, x => x.Rating);
            var targetBookIds = targetRatings.Keys.ToHashSet();

            var normU = Math.Sqrt(targetRatings.Values.Sum(v => v * v));

            if (normU == 0)
                return new List<BookListResponse>();

            var overlap = await _ctx.Reviews
                .AsNoTracking()
                .Where(r => r.UserId != userId && targetBookIds.Contains(r.BookId))
                .Select(r => new { r.UserId, r.BookId, r.Rating })
                .ToListAsync();

            if (overlap.Count == 0)
                return new List<BookListResponse>();

            var dot = new Dictionary<int, double>();
            var normV2 = new Dictionary<int, double>();

            foreach (var r in overlap)
            {
                var uRating = targetRatings[r.BookId];

                if (!dot.ContainsKey(r.UserId))
                    dot[r.UserId] = 0;

                if (!normV2.ContainsKey(r.UserId))
                    normV2[r.UserId] = 0;

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
                return new List<BookListResponse>();

            var neighborIds = sims.Select(x => x.UserId).ToList();
            var simByUser = sims.ToDictionary(x => x.UserId, x => x.Sim);

            var neighborReviewsQuery = _ctx.Reviews
                .AsNoTracking()
                .Where(r =>
                    neighborIds.Contains(r.UserId) &&
                    !targetBookIds.Contains(r.BookId) &&
                    !ownedBookSet.Contains(r.BookId));

            if (categoryId.HasValue)
            {
                neighborReviewsQuery = neighborReviewsQuery.Where(r =>
                    _ctx.BookCategories.Any(bc => bc.BookId == r.BookId && bc.CategoryId == categoryId.Value));
            }

            var neighborReviews = await neighborReviewsQuery
                .Select(r => new { r.BookId, r.UserId, r.Rating })
                .ToListAsync();

            if (neighborReviews.Count == 0)
                return new List<BookListResponse>();

            var num = new Dictionary<int, double>();
            var den = new Dictionary<int, double>();

            foreach (var r in neighborReviews)
            {
                var sim = simByUser[r.UserId];

                if (!num.ContainsKey(r.BookId))
                    num[r.BookId] = 0;

                if (!den.ContainsKey(r.BookId))
                    den[r.BookId] = 0;

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
                return new List<BookListResponse>();

            var predictedIds = predicted.Select(x => x.BookId).ToList();
            var scoreByBook = predicted.ToDictionary(x => x.BookId, x => x.Score);

            var books = await _ctx.Books
                .AsNoTracking()
                .Where(b => predictedIds.Contains(b.Id))
                .Select(b => new
                {
                    Id = b.Id,
                    Name = b.Name,
                    Rating = b.Rating,
                    RatingCount = b.RatingCount,
                    CoverImage = b.CoverImage,
                    CreatedAt = b.CreatedAt,
                    Authors = b.BookAuthors.Select(ba => new AuthorResponse
                    {
                        Id = ba.Author.Id,
                        FirstName = ba.Author.FirstName,
                        LastName = ba.Author.LastName
                    }).ToList()
                })
                .ToListAsync();

            var ordered = books
                .Select(b => new
                {
                    Book = new BookListResponse
                    {
                        Id = b.Id,
                        Name = b.Name,
                        Rating = b.Rating,
                        RatingCount = b.RatingCount,
                        CoverImage = b.CoverImage,
                        Authors = b.Authors,
                        WhyRecommended = "Preporučeno jer su korisnici sa sličnim ocjenama preporučili ovu knjigu."
                    },
                    Score = scoreByBook.GetValueOrDefault(b.Id, 0),
                    CreatedAt = b.CreatedAt
                })
                .OrderByDescending(x => x.Score)
                .ThenByDescending(x => x.CreatedAt)
                .Take(count)
                .Select(x => x.Book)
                .ToList();

            return ordered;
        }

        private BookListResponse MapToResponse(Database.Book b)
            => _mapper.Map<BookListResponse>(b);
    }
}