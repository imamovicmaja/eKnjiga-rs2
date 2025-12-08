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
using eKnjiga.Model.Enums;

namespace eKnjiga.Services
{
    public class OrderService : BaseCRUDService<OrderResponse, OrderSearchObject, Database.Order, OrderUpsertRequest, OrderUpdateRequest>, IOrderService
    {
        public OrderService(eKnjigaDbContext context, IMapper mapper) : base(context, mapper) {}

        protected override IQueryable<Order> ApplyFilter(IQueryable<Order> query, OrderSearchObject search)
        {
            if (search.UserId.HasValue)
                query = query.Where(o => o.UserId == search.UserId.Value);

            if (search.TotalPrice.HasValue)
                query = query.Where(o => o.TotalPrice == search.TotalPrice.Value);

            if (search.OrderStatus.HasValue)
                query = query.Where(o => o.OrderStatus == search.OrderStatus.Value);

            if (search.PaymentStatus.HasValue)
                query = query.Where(o => o.PaymentStatus == search.PaymentStatus.Value);

            if (search.Type.HasValue)
                query = query.Where(o => o.Type == search.Type.Value);

            return query;
        }

        public override async Task<PagedResult<OrderResponse>> GetAsync(OrderSearchObject search)
        {
            var query = _context.Orders
                .Include(o => o.User)
                    .ThenInclude(c => c.City)
                        .ThenInclude(cc => cc.Country)
                .Include(o => o.User)
                    .ThenInclude(ur => ur.Role)
                .Include(o => o.OrderItems).ThenInclude(oi => oi.Book).ThenInclude(b => b.BookAuthors).ThenInclude(ba => ba.Author)
                .Include(o => o.OrderItems).ThenInclude(oi => oi.Book).ThenInclude(b => b.BookCategories).ThenInclude(bc => bc.Category)
                .AsQueryable();

            query = ApplyFilter(query, search);

            var desc = search.IsDescending ?? true;

            if (!string.IsNullOrWhiteSpace(search.OrderBy))
            {
                switch (search.OrderBy)
                {
                    case "OrderDate":
                        query = desc
                            ? query.OrderByDescending(o => o.OrderDate)
                            : query.OrderBy(o => o.OrderDate);
                        break;

                    case "TotalPrice":
                        query = desc
                            ? query.OrderByDescending(o => o.TotalPrice)
                            : query.OrderBy(o => o.TotalPrice);
                        break;

                    case "CreatedAt":
                        query = desc
                            ? query.OrderByDescending(o => o.CreatedAt)
                            : query.OrderBy(o => o.CreatedAt);
                        break;

                    default:
                        query = query.OrderByDescending(o => o.CreatedAt);
                        break;
                }
            }
            else
            {
                query = query.OrderByDescending(o => o.CreatedAt);
            }

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
            return new PagedResult<OrderResponse>
            {
                Items = list.Select(MapToResponse).ToList(),
                TotalCount = totalCount
            };
        }

        public override async Task<OrderResponse?> GetByIdAsync(int id)
        {
            var order = await _context.Orders
                .Include(o => o.User)
                    .ThenInclude(c => c.City)
                        .ThenInclude(cc => cc.Country)
                .Include(o => o.User)
                    .ThenInclude(ur => ur.Role)
                .Include(o => o.OrderItems).ThenInclude(oi => oi.Book).ThenInclude(b => b.BookAuthors).ThenInclude(ba => ba.Author)
                .Include(o => o.OrderItems).ThenInclude(oi => oi.Book).ThenInclude(b => b.BookCategories).ThenInclude(bc => bc.Category)
                .FirstOrDefaultAsync(o => o.Id == id);

            return order != null ? MapToResponse(order) : null;
        }

        protected override async Task BeforeInsert(Order entity, OrderUpsertRequest request)
        {
            entity.OrderItems = request.OrderItems.Select(item => new OrderItem
            {
                BookId = item.BookId,
                Quantity = item.Quantity,
                UnitPrice = item.UnitPrice
            }).ToList();
        }

        private OrderResponse MapToResponse(Database.Order order)
        {
            return new OrderResponse
            {
                Id = order.Id,
                OrderDate = order.OrderDate,
                TotalPrice = order.TotalPrice,
                OrderStatus = order.OrderStatus,
                PaymentStatus = order.PaymentStatus,
                Type = order.Type,
                CreatedAt = order.CreatedAt,

                User = order.User != null ? new UserResponse
                {
                    Id = order.User.Id,
                    FirstName = order.User.FirstName,
                    LastName = order.User.LastName,
                    Email = order.User.Email,
                    Username = order.User.Username,
                    PhoneNumber = order.User.PhoneNumber,
                    CreatedAt = order.User.CreatedAt,
                    BirthDate = order.User.BirthDate,
                    Gender = order.User.Gender,
                    Role = order.User.Role != null ? new RoleResponse
                    {
                        Id = order.User.Role.Id,
                        Name = order.User.Role.Name,
                        Description = order.User.Role.Description
                    } : null,
                    City = order.User.City != null ? new CityResponse
                    {
                        Id = order.User.City.Id,
                        Name = order.User.City.Name,
                        Country = order.User.City.Country != null ? new CountryResponse
                        {
                            Id = order.User.City.Country.Id,
                            Name = order.User.City.Country.Name,
                            Code = order.User.City.Country.Code
                        } : null
                    } : null
                } : null,

                OrderItems = order.OrderItems.Select(oi => new OrderItemResponse
                {
                    Id = oi.Id,
                    Quantity = oi.Quantity,
                    UnitPrice = oi.UnitPrice,
                    Book = oi.Book != null ? new BookResponse
                    {
                        Id = oi.Book.Id,
                        Name = oi.Book.Name,
                        Description = oi.Book.Description,
                        Price = oi.Book.Price,
                        Rating = oi.Book.Rating,
                        RatingCount = oi.Book.RatingCount,
                        CreatedAt = oi.Book.CreatedAt,
                        Authors = oi.Book.BookAuthors?.Select(ba => new AuthorResponse
                        {
                            Id = ba.Author.Id,
                            FirstName = ba.Author.FirstName,
                            LastName = ba.Author.LastName
                        }).ToList() ?? new List<AuthorResponse>(),
                        Categories = oi.Book.BookCategories?.Select(bc => new CategoryResponse
                        {
                            Id = bc.Category.Id,
                            Name = bc.Category.Name
                        }).ToList() ?? new List<CategoryResponse>()
                    } : null
                }).ToList()
            };
        }

        public override async Task<OrderResponse> CreateAsync(OrderUpsertRequest request)
        {
            var entity = new Order();
            MapInsertToEntity(entity, request);

            entity.OrderItems = request.OrderItems.Select(item => new OrderItem
            {
                BookId = item.BookId,
                Quantity = item.Quantity,
                UnitPrice = item.UnitPrice
            }).ToList();

            _context.Orders.Add(entity);

            if (entity.OrderStatus == OrderStatus.Completed)
            {
                var bookIds = entity.OrderItems.Select(oi => oi.BookId).Distinct().ToList();

                var existing = await _context.UserBooks
                    .Where(ub => ub.UserId == entity.UserId && bookIds.Contains(ub.BookId))
                    .Select(ub => ub.BookId)
                    .ToListAsync();

                var toAdd = bookIds.Except(existing);
                foreach (var bookId in toAdd)
                    _context.UserBooks.Add(new UserBook { UserId = entity.UserId, BookId = bookId });
            }

            await _context.SaveChangesAsync();

            var full = await GetByIdAsync(entity.Id);
            return full ?? MapToResponse(entity);
        }

        public override async Task<OrderResponse?> UpdateAsync(int id, OrderUpdateRequest request)
        {
            var entity = await _context.Orders.FindAsync(id);
            if (entity == null)
                return null;

            await _context.Entry(entity).Collection(e => e.OrderItems).LoadAsync();

            var wasCompleted = entity.OrderStatus == OrderStatus.Completed;

            await BeforeUpdate(entity, request);

            MapUpdateToEntity(entity, request);

            await _context.SaveChangesAsync();

            if (!wasCompleted && entity.OrderStatus == OrderStatus.Completed)
            {
                var bookIds = entity.OrderItems.Select(oi => oi.BookId).Distinct().ToList();

                var existing = await _context.UserBooks
                    .Where(ub => ub.UserId == entity.UserId && bookIds.Contains(ub.BookId))
                    .Select(ub => ub.BookId)
                    .ToListAsync();

                var toAdd = bookIds.Except(existing);
                foreach (var bookId in toAdd)
                    _context.UserBooks.Add(new UserBook { UserId = entity.UserId, BookId = bookId });

                await _context.SaveChangesAsync();
            }

            var full = await GetByIdAsync(entity.Id);
            return full ?? MapToResponse(entity);
        }

    }
}
