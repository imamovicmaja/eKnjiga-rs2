using eKnjiga.Services.Database;
using Microsoft.EntityFrameworkCore;
using System.Collections.Generic;
using System.Threading.Tasks;
using eKnjiga.Model.Responses;
using eKnjiga.Model.Requests;
using eKnjiga.Model.SearchObjects;
using System.Linq;
using System;
using MapsterMapper;

namespace eKnjiga.Services
{
    public abstract class BaseService<T, TSearch, TEntity> : IService<T, TSearch> where T : class where TSearch : BaseSearchObject where TEntity : class
    {
        private readonly eKnjigaDbContext _context;
        protected readonly IMapper _mapper;

        public BaseService(eKnjigaDbContext context, IMapper mapper)
        {
            _context = context;
            _mapper = mapper;
        }

        public virtual async Task<PagedResult<T>> GetAsync(TSearch search)
        {
            search ??= Activator.CreateInstance<TSearch>();

            var query = _context.Set<TEntity>().AsQueryable();

            query = ApplyFilter(query, search);
            query = ApplyOrder(query);

            var page = search.Page < 1 ? 1 : search.Page;
            var pageSize = search.PageSize < 1 ? 10 : search.PageSize;

            int? totalCount = null;

            if (search.IncludeTotalCount)
            {
                totalCount = await query.CountAsync();
            }

            query = query
                .Skip((page - 1) * pageSize)
                .Take(pageSize);

            var list = await query.ToListAsync();

            return new PagedResult<T>
            {
                Items = list.Select(MapToResponse).ToList(),
                TotalCount = totalCount
            };
        }

        protected virtual IQueryable<TEntity> ApplyFilter(IQueryable<TEntity> query, TSearch search)
        {
            return query;
        }

        protected virtual IQueryable<TEntity> ApplyOrder(IQueryable<TEntity> query)
        {
            var idProperty = typeof(TEntity).GetProperty("Id");

            if (idProperty == null)
            {
                return query;
            }

            return query.OrderByDescending(e => EF.Property<int>(e, "Id"));
        }

        public virtual async Task<T?> GetByIdAsync(int id)
        {
            var entity = await _context.Set<TEntity>().FindAsync(id);
            if (entity == null)
                return null;
            
            return MapToResponse(entity);
        }

        protected virtual T MapToResponse(TEntity entity) {
            return _mapper.Map<T>(entity);
        }
        
    }
} 