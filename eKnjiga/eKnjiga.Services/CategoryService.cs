using eKnjiga.Model.Requests;
using eKnjiga.Model.Responses;
using eKnjiga.Model.SearchObjects;
using eKnjiga.Services.Database;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using System.Linq;
using System.Threading.Tasks;

namespace eKnjiga.Services
{
    public class CategoryService : BaseCRUDService<CategoryResponse, CategorySearchObject, Database.Category, CategoryUpsertRequest, CategoryUpsertRequest>, ICategoryService
    {
        public CategoryService(eKnjigaDbContext context, IMapper mapper) : base(context, mapper) { }

        protected override async Task BeforeInsert(Category entity, CategoryUpsertRequest request)
        {
            entity.BookCategories = request.BookIds.Select(id => new BookCategory { BookId = id }).ToList();
        }

        protected override async Task BeforeUpdate(Category entity, CategoryUpsertRequest request)
        {
            _context.BookCategories.RemoveRange(_context.BookCategories.Where(x => x.CategoryId == entity.Id));
            entity.BookCategories = request.BookIds.Select(id => new BookCategory
            {
                BookId = id,
                CategoryId = entity.Id
            }).ToList();
        }

        protected override IQueryable<Category> ApplyFilter(IQueryable<Category> query, CategorySearchObject search)
        {
            if (!string.IsNullOrEmpty(search.Name))
                query = query.Where(c => c.Name.Contains(search.Name));

            return query;
        }

        public override async Task<CategoryResponse?> GetByIdAsync(int id)
        {
            var category = await _context.Categories
                .FirstOrDefaultAsync(c => c.Id == id);

            return category != null ? MapToResponse(category) : null;
        }

        private CategoryResponse MapToResponse(Database.Category category)
        {
            return new CategoryResponse
            {
                Id = category.Id,
                Name = category.Name
            };
        }
    }
}