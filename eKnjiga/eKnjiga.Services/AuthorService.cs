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

        public override async Task<AuthorResponse?> GetByIdAsync(int id)
        {
            var author = await _context.Authors
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
                Description = author.Description
            };
        }
    }
}