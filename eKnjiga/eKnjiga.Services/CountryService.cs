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
    public class CountryService : BaseCRUDService<CountryResponse, CountrySearchObject, Database.Country, CountryUpsertRequest, CountryUpsertRequest>, ICountryService
    {
        public CountryService(eKnjigaDbContext context, IMapper mapper) : base(context, mapper) {}

        protected override IQueryable<Country> ApplyFilter(IQueryable<Country> query, CountrySearchObject search)
        {
            if (!string.IsNullOrEmpty(search.Name))
                query = query.Where(c => c.Name.Contains(search.Name));

            if (!string.IsNullOrEmpty(search.Code))
                query = query.Where(c => c.Code.Contains(search.Code));
            
            return query;
        }
    }
}
