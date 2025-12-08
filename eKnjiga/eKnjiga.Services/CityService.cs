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
    public class CityService : BaseCRUDService<CityResponse, CitySearchObject, Database.City, CityUpsertRequest, CityUpsertRequest>, ICityService
    {
        public CityService(eKnjigaDbContext context, IMapper mapper) : base(context, mapper) {}

        protected override IQueryable<City> ApplyFilter(IQueryable<City> query, CitySearchObject search)
        {
            if (!string.IsNullOrEmpty(search.Name))
                query = query.Where(c => c.Name.Contains(search.Name));

            if (search.ZipCode.HasValue)
                query = query.Where(b => b.ZipCode == search.ZipCode.Value);
            
            return query;
        }

        public override async Task<PagedResult<CityResponse>> GetAsync(CitySearchObject search)
        {
            var query = _context.Cities
                .Include(c => c.Country)
                .AsQueryable();

            query = ApplyFilter(query, search);

            int? totalCount = null;
            if (search.IncludeTotalCount)
            {
                totalCount = await query.CountAsync();
            }

            if (!search.RetrieveAll)
            {
                if (search.Page.HasValue)
                {
                    query = query.Skip(search.Page.Value * search.PageSize.Value);
                }
                if (search.PageSize.HasValue)
                {
                    query = query.Take(search.PageSize.Value);
                }
            }

            var list = await query.ToListAsync();
            return new PagedResult<CityResponse>
            {
                Items = list.Select(MapToResponse).ToList(),
                TotalCount = totalCount
            };
        }

        public override async Task<CityResponse?> GetByIdAsync(int id)
        {
            var city = await _context.Cities
                .Include(c => c.Country)
                .FirstOrDefaultAsync(c => c.Id == id);

            return city != null ? MapToResponse(city) : null;
        }

        private CityResponse MapToResponse(Database.City city)
        {
            return new CityResponse
            {
                Id = city.Id,
                Name = city.Name,
                ZipCode = city.ZipCode,
                Country = city.Country != null ? new CountryResponse
                {
                    Id = city.Country.Id,
                    Name = city.Country.Name,
                    Code = city.Country.Code
                } : null
            };
        }
    }
}
