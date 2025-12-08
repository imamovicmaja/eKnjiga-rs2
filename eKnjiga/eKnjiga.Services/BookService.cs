using eKnjiga.Model.Requests;
using eKnjiga.Model.Responses;
using eKnjiga.Model.SearchObjects;
using eKnjiga.Services.Database;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using System;
using System.Linq;
using System.Threading.Tasks;
using System.Collections.Generic;

namespace eKnjiga.Services
{
    public class BookService : BaseCRUDService<BookResponse, BookSearchObject, Database.Book, BookUpsertRequest, BookUpsertRequest>, IBookService
    {
        public BookService(eKnjigaDbContext context, IMapper mapper) : base(context, mapper) {}

        protected override IQueryable<Book> ApplyFilter(IQueryable<Book> query, BookSearchObject search)
        {
            if (!string.IsNullOrEmpty(search.Name))
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

        protected override async Task BeforeInsert(Book entity, BookUpsertRequest request)
        {
            entity.BookAuthors = request.AuthorIds.Select(id => new BookAuthor { AuthorId = id }).ToList();
            entity.BookCategories = request.CategoryIds.Select(id => new BookCategory { CategoryId = id }).ToList();
        }

        protected override async Task BeforeUpdate(Book entity, BookUpsertRequest request)
        {
            _context.BookAuthors.RemoveRange(_context.BookAuthors.Where(x => x.BookId == entity.Id));
            _context.BookCategories.RemoveRange(_context.BookCategories.Where(x => x.BookId == entity.Id));

            entity.BookAuthors = request.AuthorIds.Select(id => new BookAuthor { AuthorId = id, BookId = entity.Id }).ToList();
            entity.BookCategories = request.CategoryIds.Select(id => new BookCategory { CategoryId = id, BookId = entity.Id }).ToList();
        }

        protected override void MapUpdateToEntity(Book entity, BookUpsertRequest request)
        {
            entity.Name = request.Name;
            entity.Description = request.Description;
            entity.Price = request.Price;

            if (request.CoverImage != null)
            {
                entity.CoverImage = request.CoverImage;
            }

            if (request.PdfFile != null)
            {
                entity.PdfFile = request.PdfFile;
            }
        }

        public async Task<PagedResult<BookResponse>> GetNewAsync()
        {
            var list = await _context.Books
                .Include(b => b.BookAuthors).ThenInclude(ba => ba.Author)
                .Include(b => b.BookCategories).ThenInclude(bc => bc.Category)
                .OrderByDescending(b => b.CreatedAt)
                .Take(10)
                .ToListAsync();

            return new PagedResult<BookResponse>
            {
                Items = list.Select(MapToResponse).ToList(),
                TotalCount = list.Count
            };
        }

        public override async Task<PagedResult<BookResponse>> GetAsync(BookSearchObject search)
        {
            var query = _context.Books
                .Include(b => b.BookAuthors).ThenInclude(ba => ba.Author)
                .Include(b => b.BookCategories).ThenInclude(bc => bc.Category)
                .AsQueryable();

            query = ApplyFilter(query, search);

            int? totalCount = null;
            if (search.IncludeTotalCount)
            {
                totalCount = await query.CountAsync();
            }

            if (!search.RetrieveAll)
            {
                if (search.Page.HasValue && search.PageSize.HasValue)
                {
                    query = query
                        .Skip(search.Page.Value * search.PageSize.Value)
                        .Take(search.PageSize.Value);
                }
            }

            var list = await query.ToListAsync();

            return new PagedResult<BookResponse>
            {
                Items = list.Select(MapToResponse).ToList(),
                TotalCount = totalCount
            };
        }

        public override async Task<BookResponse?> GetByIdAsync(int id)
        {
            var book = await _context.Books
                .Include(b => b.BookAuthors).ThenInclude(ba => ba.Author)
                .Include(b => b.BookCategories).ThenInclude(bc => bc.Category)
                .FirstOrDefaultAsync(b => b.Id == id);

            return book != null ? MapToResponse(book) : null;
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
                PdfFile = book.PdfFile,
                Rating = book.Rating,
                RatingCount = book.RatingCount,
                CreatedAt = book.CreatedAt,
                Authors = book.BookAuthors?.Select(ba => new AuthorResponse
                {
                    Id = ba.Author.Id,
                    FirstName = ba.Author.FirstName,
                    LastName = ba.Author.LastName
                }).ToList() ?? new List<AuthorResponse>(),
                Categories = book.BookCategories?.Select(bc => new CategoryResponse
                {
                    Id = bc.Category.Id,
                    Name = bc.Category.Name
                }).ToList() ?? new List<CategoryResponse>()
            };
        }
    }
}