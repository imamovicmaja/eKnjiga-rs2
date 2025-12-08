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
    public class AuthorService : BaseCRUDService<AuthorResponse, AuthorSearchObject, Database.Author, AuthorUpsertRequest, AuthorUpsertRequest>, IAuthorService
    {
        public AuthorService(eKnjigaDbContext context, IMapper mapper) : base(context, mapper)
        {
        }

        protected override IQueryable<Database.Author> ApplyFilter(IQueryable<Database.Author> query, AuthorSearchObject search)
        {
            if (!string.IsNullOrEmpty(search.FirstName))
            {
                query = query.Where(a => a.FirstName.Contains(search.FirstName));
            }

            if (!string.IsNullOrEmpty(search.LastName))
            {
                query = query.Where(a => a.LastName.Contains(search.LastName));
            }

            return query;
        }

        protected override async Task BeforeInsert(Database.Author entity, AuthorUpsertRequest request)
        {
            if (await _context.Authors.AnyAsync(a => a.FirstName == request.FirstName && a.LastName == request.LastName))
            {
                throw new InvalidOperationException("Autor s ovim imenom i prezimenom već postoji.");
            }
        }

        protected override async Task BeforeUpdate(Database.Author entity, AuthorUpsertRequest request)
        {
            if (await _context.Authors.AnyAsync(a => a.FirstName == request.FirstName && a.LastName == request.LastName && a.Id != entity.Id))
            {
                throw new InvalidOperationException("Autor s ovim imenom i prezimenom već postoji.");
            }
        }

        public override async Task<PagedResult<AuthorResponse>> GetAsync(AuthorSearchObject search)
        {
            var query = _context.Authors
                .Include(a => a.BookAuthors).ThenInclude(ba => ba.Book).ThenInclude(b => b.BookCategories).ThenInclude(bc => bc.Category)
                .Include(a => a.BookAuthors).ThenInclude(ba => ba.Book).ThenInclude(b => b.BookAuthors).ThenInclude(ba => ba.Author)
                .AsQueryable();

            query = ApplyFilter(query, search);

            int? totalCount = null;
            if (search.IncludeTotalCount || !search.RetrieveAll)
            {
                totalCount = await query.CountAsync();
            }

            if (!search.RetrieveAll)
            {
                if (search.Page.HasValue)
                    query = query.Skip(search.Page.Value * search.PageSize.Value);
                if (search.PageSize.HasValue)
                    query = query.Take(search.PageSize.Value);
            }

            var list = await query.ToListAsync();
            return new PagedResult<AuthorResponse>
            {
                Items = list.Select(MapToResponse).ToList(),
                TotalCount = totalCount
            };
        }

        public override async Task<AuthorResponse?> GetByIdAsync(int id)
        {
            var author = await _context.Authors
                .Include(a => a.BookAuthors).ThenInclude(ba => ba.Book).ThenInclude(b => b.BookCategories).ThenInclude(bc => bc.Category)
                .Include(a => a.BookAuthors).ThenInclude(ba => ba.Book).ThenInclude(b => b.BookAuthors).ThenInclude(ba => ba.Author)
                .FirstOrDefaultAsync(a => a.Id == id);

            return author != null ? MapToResponse(author) : null;
        }

        private AuthorResponse MapToResponse(Database.Author author)
        {
            return new AuthorResponse
            {
                Id = author.Id,
                FirstName = author.FirstName,
                LastName = author.LastName,
                BirthDate = author.BirthDate,
                DeathDate = author.DeathDate,
                Description = author.Description,
                Books = author.BookAuthors?.Select(ba => new BookResponse
                {
                    Id = ba.Book.Id,
                    Name = ba.Book.Name,
                    Description = ba.Book.Description,
                    Price = ba.Book.Price,
                    CoverImage = ba.Book.CoverImage,
                    PdfFile = ba.Book.PdfFile,
                    Rating = ba.Book.Rating,
                    RatingCount = ba.Book.RatingCount,
                    CreatedAt = ba.Book.CreatedAt,
                    Authors = ba.Book.BookAuthors?.Select(ba2 => new AuthorResponse
                    {
                        Id = ba2.Author.Id,
                        FirstName = ba2.Author.FirstName,
                        LastName = ba2.Author.LastName
                    }).ToList() ?? new List<AuthorResponse>(),
                    Categories = ba.Book.BookCategories?.Select(bc => new CategoryResponse
                    {
                        Id = bc.Category.Id,
                        Name = bc.Category.Name
                    }).ToList() ?? new List<CategoryResponse>()
                }).ToList() ?? new List<BookResponse>()
            };
        }
    }
}
