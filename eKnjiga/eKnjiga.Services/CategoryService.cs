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
    public class CategoryService : BaseCRUDService<CategoryResponse, CategorySearchObject, Database.Category, CategoryUpsertRequest, CategoryUpsertRequest>, ICategoryService
    {
        public CategoryService(eKnjigaDbContext context, IMapper mapper) : base(context, mapper) {}

        protected override async Task BeforeInsert(Category entity, CategoryUpsertRequest request)
        {
            entity.BookCategories = request.BookIds.Select(id => new BookCategory { BookId = id }).ToList();
        }

        protected override async Task BeforeUpdate(Category entity, CategoryUpsertRequest request)
        {
            _context.BookCategories.RemoveRange(_context.BookCategories.Where(x => x.CategoryId == entity.Id));
            entity.BookCategories = request.BookIds.Select(id => new BookCategory { BookId = id, CategoryId = entity.Id }).ToList();
        }

        protected override IQueryable<Category> ApplyFilter(IQueryable<Category> query, CategorySearchObject search)
        {
            if (!string.IsNullOrEmpty(search.Name))
                query = query.Where(c => c.Name.Contains(search.Name));
            
            return query;
        }

        public override async Task<PagedResult<CategoryResponse>> GetAsync(CategorySearchObject search)
        {
            var query = _context.Categories
                .Include(c => c.BookCategories).ThenInclude(bc => bc.Book).ThenInclude(b => b.BookAuthors).ThenInclude(ba => ba.Author)
                .Include(c => c.BookCategories).ThenInclude(bc => bc.Book).ThenInclude(b => b.BookCategories).ThenInclude(bc => bc.Category)
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
            return new PagedResult<CategoryResponse>
            {
                Items = list.Select(MapToResponse).ToList(),
                TotalCount = totalCount
            };
        }

        public override async Task<CategoryResponse?> GetByIdAsync(int id)
        {
            var category = await _context.Categories
                .Include(c => c.BookCategories).ThenInclude(bc => bc.Book).ThenInclude(b => b.BookAuthors).ThenInclude(ba => ba.Author)
                .Include(c => c.BookCategories).ThenInclude(bc => bc.Book).ThenInclude(b => b.BookCategories).ThenInclude(bc => bc.Category)
                .FirstOrDefaultAsync(c => c.Id == id);

            return category != null ? MapToResponse(category) : null;
        }

        private CategoryResponse MapToResponse(Database.Category category)
        {
            return new CategoryResponse
            {
                Id = category.Id,
                Name = category.Name,
                Books = category.BookCategories?.Select(bc => new BookResponse
                {
                    Id = bc.Book.Id,
                    Name = bc.Book.Name,
                    Description = bc.Book.Description,
                    Price = bc.Book.Price,
                    CoverImage = bc.Book.CoverImage,
                    PdfFile = bc.Book.PdfFile,
                    Rating = bc.Book.Rating,
                    RatingCount = bc.Book.RatingCount,
                    CreatedAt = bc.Book.CreatedAt,
                    Authors = bc.Book.BookAuthors?.Select(ba => new AuthorResponse
                    {
                        Id = ba.Author.Id,
                        FirstName = ba.Author.FirstName,
                        LastName = ba.Author.LastName
                    }).ToList() ?? new List<AuthorResponse>(),
                    Categories = bc.Book.BookCategories?.Select(bcc => new CategoryResponse
                    {
                        Id = bcc.Category.Id,
                        Name = bcc.Category.Name,
                        Books = new List<BookResponse>()
                    }).ToList() ?? new List<CategoryResponse>()
                }).ToList() ?? new List<BookResponse>()
            };
        }
    }
}
