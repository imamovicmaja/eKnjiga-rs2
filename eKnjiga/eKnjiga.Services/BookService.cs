using eKnjiga.Model;
using eKnjiga.Model.Enums;
using eKnjiga.Model.Requests;
using eKnjiga.Model.Responses;
using eKnjiga.Model.SearchObjects;
using eKnjiga.Services.Database;
using Microsoft.EntityFrameworkCore;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace eKnjiga.Services
{
    public class BookService : IBookService
    {
        private readonly eKnjigaDbContext _context;

        public BookService(eKnjigaDbContext context)
        {
            _context = context;
        }

        public async Task<PagedResult<BookListResponse>> GetAsync(BookSearchObject search)
        {
            var query = _context.Books.AsQueryable();

            query = ApplyFilter(query, search);

            int? totalCount = null;
            if (search.IncludeTotalCount)
            {
                totalCount = await query.CountAsync();
            }

            if (!search.RetrieveAll && search.Page.HasValue && search.PageSize.HasValue)
            {
                query = query
                    .Skip(search.Page.Value * search.PageSize.Value)
                    .Take(search.PageSize.Value);
            }

            var list = await query
                .Select(book => new BookListResponse
                {
                    Id = book.Id,
                    Name = book.Name,
                    Rating = book.Rating,
                    RatingCount = book.RatingCount,
                    CoverImage = book.CoverImage,
                    Authors = book.BookAuthors.Select(ba => new AuthorResponse
                    {
                        Id = ba.Author.Id,
                        FirstName = ba.Author.FirstName,
                        LastName = ba.Author.LastName
                    }).ToList()
                })
                .ToListAsync();

            return new PagedResult<BookListResponse>
            {
                Items = list,
                TotalCount = totalCount
            };
        }

        public async Task<PagedResult<BookListResponse>> GetNewAsync()
        {
            var list = await _context.Books
                .OrderByDescending(b => b.CreatedAt)
                .Take(10)
                .Select(book => new BookListResponse
                {
                    Id = book.Id,
                    Name = book.Name,
                    Rating = book.Rating,
                    RatingCount = book.RatingCount,
                    CoverImage = book.CoverImage,
                    Authors = book.BookAuthors.Select(ba => new AuthorResponse
                    {
                        Id = ba.Author.Id,
                        FirstName = ba.Author.FirstName,
                        LastName = ba.Author.LastName
                    }).ToList()
                })
                .ToListAsync();

            return new PagedResult<BookListResponse>
            {
                Items = list,
                TotalCount = list.Count
            };
        }

        public async Task<BookResponse?> GetByIdAsync(int id)
        {
            var book = await _context.Books
                .Include(b => b.BookAuthors)
                    .ThenInclude(ba => ba.Author)
                .Include(b => b.BookCategories)
                    .ThenInclude(bc => bc.Category)
                .FirstOrDefaultAsync(b => b.Id == id);

            return book == null ? null : MapToResponse(book);
        }

        public async Task<byte[]?> GetPdfAsync(int id)
        {
            return await _context.Books
                .Where(b => b.Id == id)
                .Select(b => b.PdfFile)
                .FirstOrDefaultAsync();
        }

        public async Task<byte[]?> GetPdfForUserAsync(int bookId, int userId)
        {
            var hasAccess = await _context.OrderItems
                .AnyAsync(oi => oi.Order.UserId == userId &&
                                oi.BookId == bookId &&
                                oi.IsPdfPurchase &&
                                oi.Order.PaymentStatus == PaymentStatus.Paid);

            if (!hasAccess)
                return null;

            var book = await _context.Books.FindAsync(bookId);
            return book?.PdfFile;
        }

        public async Task<BookResponse> InsertAsync(BookUpsertRequest request)
        {
            var entity = new Book
            {
                Name = request.Name,
                Description = request.Description,
                Price = request.Price,
                CoverImage = request.CoverImage,
                PdfFile = request.PdfFile
            };

            entity.BookAuthors = request.AuthorIds
                .Select(id => new BookAuthor { AuthorId = id })
                .ToList();

            entity.BookCategories = request.CategoryIds
                .Select(id => new BookCategory { CategoryId = id })
                .ToList();

            _context.Books.Add(entity);
            await _context.SaveChangesAsync();

            var inserted = await _context.Books
                .Include(b => b.BookAuthors)
                    .ThenInclude(ba => ba.Author)
                .Include(b => b.BookCategories)
                    .ThenInclude(bc => bc.Category)
                .FirstAsync(b => b.Id == entity.Id);

            return MapToResponse(inserted);
        }

        public async Task<BookResponse?> UpdateAsync(int id, BookUpsertRequest request)
        {
            var entity = await _context.Books
                .Include(b => b.BookAuthors)
                .Include(b => b.BookCategories)
                .FirstOrDefaultAsync(b => b.Id == id);

            if (entity == null)
                return null;

            entity.Name = request.Name;
            entity.Description = request.Description;
            entity.Price = request.Price;

            if (request.CoverImage != null)
                entity.CoverImage = request.CoverImage;

            if (request.PdfFile != null)
                entity.PdfFile = request.PdfFile;

            _context.BookAuthors.RemoveRange(entity.BookAuthors);
            _context.BookCategories.RemoveRange(entity.BookCategories);

            entity.BookAuthors = request.AuthorIds
                .Select(authorId => new BookAuthor
                {
                    BookId = entity.Id,
                    AuthorId = authorId
                })
                .ToList();

            entity.BookCategories = request.CategoryIds
                .Select(categoryId => new BookCategory
                {
                    BookId = entity.Id,
                    CategoryId = categoryId
                })
                .ToList();

            await _context.SaveChangesAsync();

            var updated = await _context.Books
                .Include(b => b.BookAuthors)
                    .ThenInclude(ba => ba.Author)
                .Include(b => b.BookCategories)
                    .ThenInclude(bc => bc.Category)
                .FirstAsync(b => b.Id == entity.Id);

            return MapToResponse(updated);
        }

        public async Task<bool> DeleteAsync(int id)
        {
            var entity = await _context.Books
                .Include(b => b.BookAuthors)
                .Include(b => b.BookCategories)
                .FirstOrDefaultAsync(b => b.Id == id);

            if (entity == null)
                return false;

            if (entity.BookAuthors.Any())
                _context.BookAuthors.RemoveRange(entity.BookAuthors);

            if (entity.BookCategories.Any())
                _context.BookCategories.RemoveRange(entity.BookCategories);

            _context.Books.Remove(entity);
            await _context.SaveChangesAsync();

            return true;
        }

        public async Task<bool> UpdateCoverAsync(int id, string coverImagePath)
        {
            var entity = await _context.Books.FirstOrDefaultAsync(b => b.Id == id);

            if (entity == null)
                return false;

            entity.CoverImage = coverImagePath;
            await _context.SaveChangesAsync();

            return true;
        }

        public async Task<bool> UpdatePdfAsync(int id, byte[] pdfBytes)
        {
            var entity = await _context.Books.FirstOrDefaultAsync(b => b.Id == id);

            if (entity == null)
                return false;

            entity.PdfFile = pdfBytes;
            await _context.SaveChangesAsync();

            return true;
        }

        private IQueryable<Book> ApplyFilter(IQueryable<Book> query, BookSearchObject search)
        {
            if (!string.IsNullOrWhiteSpace(search.Name))
            {
                query = query.Where(b => b.Name.Contains(search.Name));
            }

            if (search.CategoryId.HasValue)
            {
                query = query.Where(b =>
                    b.BookCategories.Any(bc => bc.CategoryId == search.CategoryId.Value));
            }

            return query;
        }

        private BookListResponse MapToListResponse(Book book)
        {
            return new BookListResponse
            {
                Id = book.Id,
                Name = book.Name,
                Rating = book.Rating,
                RatingCount = book.RatingCount,
                CoverImage = book.CoverImage,
                Authors = book.BookAuthors?.Select(ba => new AuthorResponse
                {
                    Id = ba.Author.Id,
                    FirstName = ba.Author.FirstName,
                    LastName = ba.Author.LastName,
                    BirthDate = ba.Author.BirthDate,
                    DeathDate = ba.Author.DeathDate,
                    Description = ba.Author.Description
                }).ToList() ?? new List<AuthorResponse>()
            };
        }

        private BookResponse MapToResponse(Book book)
        {
            return new BookResponse
            {
                Id = book.Id,
                Name = book.Name,
                Description = book.Description,
                Price = book.Price,
                CoverImage = book.CoverImage,
                Rating = book.Rating,
                RatingCount = book.RatingCount,
                CreatedAt = book.CreatedAt,
                Authors = book.BookAuthors?.Select(ba => new AuthorResponse
                {
                    Id = ba.Author.Id,
                    FirstName = ba.Author.FirstName,
                    LastName = ba.Author.LastName,
                    BirthDate = ba.Author.BirthDate,
                    DeathDate = ba.Author.DeathDate,
                    Description = ba.Author.Description
                }).ToList() ?? new List<AuthorResponse>(),
                Categories = book.BookCategories?.Select(bc => new CategoryResponse
                {
                    Id = bc.Category.Id,
                    Name = bc.Category.Name
                }).ToList() ?? new List<CategoryResponse>(),

                AuthorIds = book.BookAuthors?.Select(ba => ba.AuthorId).ToList() ?? new List<int>(),
                CategoryIds = book.BookCategories?.Select(bc => bc.CategoryId).ToList() ?? new List<int>()
            };
        }
    }
}