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
    public class RoleService : BaseCRUDService<RoleResponse, RoleSearchObject, Database.Role, RoleUpsertRequest, RoleUpsertRequest>, IRoleService
    {
        public RoleService(eKnjigaDbContext context, IMapper mapper) : base(context, mapper)
        {
        }

        protected override IQueryable<Database.Role> ApplyFilter(IQueryable<Database.Role> query, RoleSearchObject search)
        {
            if (!string.IsNullOrEmpty(search.Name))
            {
                query = query.Where(r => r.Name.Contains(search.Name));
            }

            return query;
        }

        protected override async Task BeforeInsert(Database.Role entity, RoleUpsertRequest request)
        {
            // Check for duplicate role name
            if (await _context.Roles.AnyAsync(r => r.Name == request.Name))
            {
                throw new InvalidOperationException("Uloga s ovim imenom već postoji.");
            }
        }

        protected override async Task BeforeUpdate(Database.Role entity, RoleUpsertRequest request)
        {
            // Check for duplicate role name (excluding current role)
            if (await _context.Roles.AnyAsync(r => r.Name == request.Name && r.Id != entity.Id))
            {
                throw new InvalidOperationException("Uloga s ovim imenom već postoji.");
            }
        }

        public async Task<RoleResponse?> GetByNameAsync(string name)
        {
            var role = await _context.Roles
                .FirstOrDefaultAsync(r => r.Name.ToLower() == name.ToLower());

            return role == null ? null : MapToResponse(role);
        }

    }
} 