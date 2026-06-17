using eKnjiga.Model.Constants;
using eKnjiga.Model.Enums;
using eKnjiga.Model.Requests;
using eKnjiga.Model.Responses;
using eKnjiga.Model.SearchObjects;
using eKnjiga.Services.Database;
using eKnjiga.Services.Exceptions;
using MapsterMapper;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;


namespace eKnjiga.Services
{
    public class OrderService : BaseCRUDService<OrderResponse, OrderSearchObject, Database.Order, OrderUpsertRequest, OrderUpdateRequest>, IOrderService
    {
        private readonly IHttpContextAccessor _httpContextAccessor;
        private readonly INotificationService _notificationService;
        public OrderService(
            eKnjigaDbContext context,
            IMapper mapper,
            IHttpContextAccessor httpContextAccessor,
            INotificationService notificationService)
            : base(context, mapper)
        {
            _httpContextAccessor = httpContextAccessor;
            _notificationService = notificationService;
        }

        private int? GetCurrentUserId()
        {
            var user = _httpContextAccessor.HttpContext?.User;

            var userIdClaim =
                user?.FindFirst(ClaimTypes.NameIdentifier)?.Value ??
                user?.FindFirst("UserId")?.Value ??
                user?.FindFirst("Id")?.Value;

            if (int.TryParse(userIdClaim, out var userId))
                return userId;

            return null;
        }

        private bool IsAdmin()
        {
            var user = _httpContextAccessor.HttpContext?.User;

            if (user == null)
                return false;

            return user.IsInRole(RoleNames.Admin) ||
                   user.Claims.Any(c =>
                       (c.Type == ClaimTypes.Role || c.Type == "role" || c.Type == "Role") &&
                       c.Value == RoleNames.Admin);
        }

        private bool IsEmployee()
        {
            var user = _httpContextAccessor.HttpContext?.User;

            if (user == null)
                return false;

            return user.IsInRole(RoleNames.Employee) ||
                   user.Claims.Any(c =>
                       (c.Type == ClaimTypes.Role || c.Type == "role" || c.Type == "Role") &&
                       c.Value == RoleNames.Employee);
        }

        private bool IsStaff()
        {
            return IsAdmin() || IsEmployee();
        }

        private void EnsureUserAuthenticated()
        {
            if (!GetCurrentUserId().HasValue)
                throw new UnauthorizedAccessException("User is not authenticated.");
        }

        private void EnsureCanAccessOrder(Database.Order order)
        {
            if (IsStaff())
                return;

            var currentUserId = GetCurrentUserId();

            if (!currentUserId.HasValue)
                throw new UnauthorizedAccessException("User is not authenticated.");

            if (order.UserId != currentUserId.Value)
                throw new UnauthorizedAccessException("You are not allowed to access this order.");
        }

        private void EnsureStaff()
        {
            if (!IsStaff())
                throw new UnauthorizedAccessException("Samo administrator ili uposlenik može mijenjati status narudžbe.");
        }

        private void ValidateOrderStatusTransition(OrderStatus current, OrderStatus next)
        {
            if (current == next)
                return;

            if (current == OrderStatus.Completed || current == OrderStatus.Cancelled)
            {
                throw new UserException(
                    $"Status '{current}' je završni status i ne može se mijenjati.",
                    400
                );
            }

            if ((int)next < (int)current)
            {
                throw new UserException(
                    $"Promjena statusa iz '{current}' u '{next}' nije dozvoljena.",
                    400
                );
            }
        }

        private void ValidatePaymentStatusTransition(PaymentStatus current, PaymentStatus next)
        {
            if (current == next)
                return;

            var allowed = current switch
            {
                PaymentStatus.Unpaid =>
                    next == PaymentStatus.Pending ||
                    next == PaymentStatus.Paid ||
                    next == PaymentStatus.Failed,

                PaymentStatus.Pending =>
                    next == PaymentStatus.Paid ||
                    next == PaymentStatus.Failed,

                PaymentStatus.Paid =>
                    next == PaymentStatus.Refunded,

                PaymentStatus.Refunded => false,
                PaymentStatus.Failed => false,

                _ => false
            };

            if (!allowed)
            {
                throw new UserException(
                    $"Promjena statusa plaćanja iz '{current}' u '{next}' nije dozvoljena.",
                    400
                );
            }
        }

        private async Task AddPdfBooksToUserBooksAsync(Order entity)
        {
            if (entity.Type != OrderType.Purchase)
                return;

            if (entity.PaymentStatus != PaymentStatus.Paid)
                return;

            var bookIds = entity.OrderItems
                .Where(oi => oi.IsPdfPurchase)
                .Select(oi => oi.BookId)
                .Distinct()
                .ToList();

            if (!bookIds.Any())
                return;

            var existing = await _context.UserBooks
                .Where(ub => ub.UserId == entity.UserId && bookIds.Contains(ub.BookId))
                .Select(ub => ub.BookId)
                .ToListAsync();

            var toAdd = bookIds.Except(existing);

            foreach (var bookId in toAdd)
            {
                _context.UserBooks.Add(new UserBook
                {
                    UserId = entity.UserId,
                    BookId = bookId
                });
            }
        }

        private async Task ValidatePdfPurchaseAsync(OrderUpsertRequest request, int userId)
        {
            var pdfBookIds = request.OrderItems
                .Where(x => x.IsPdfPurchase)
                .Select(x => x.BookId)
                .Distinct()
                .ToList();

            if (!pdfBookIds.Any())
                return;

            var alreadyOwnedBooks = await _context.UserBooks
                .Where(ub => ub.UserId == userId && pdfBookIds.Contains(ub.BookId))
                .Select(ub => ub.BookId)
                .ToListAsync();

            if (alreadyOwnedBooks.Any())
            {
                throw new InvalidOperationException("Već ste kupili PDF verziju ove knjige.");
            }

            var duplicatePdfInRequest = request.OrderItems
                .Where(x => x.IsPdfPurchase)
                .GroupBy(x => x.BookId)
                .Any(g => g.Count() > 1);

            if (duplicatePdfInRequest)
            {
                throw new InvalidOperationException("Ista PDF knjiga je dodana više puta u narudžbu.");
            }
        }

        protected override IQueryable<Order> ApplyFilter(IQueryable<Order> query, OrderSearchObject search)
        {
            if (search.UserId.HasValue)
                query = query.Where(o => o.UserId == search.UserId.Value);

            if (search.TotalPrice.HasValue)
                query = query.Where(o => o.TotalPrice == search.TotalPrice.Value);

            if (search.OrderStatus.HasValue)
                query = query.Where(o => o.OrderStatus == search.OrderStatus.Value);

            if (search.ExcludeCompleted == true)
                query = query.Where(o => o.OrderStatus != OrderStatus.Completed);

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
                .Include(o => o.StatusChangedByUser)
                .Include(o => o.OrderItems)
                    .ThenInclude(oi => oi.Book)
                        .ThenInclude(b => b.BookAuthors)
                            .ThenInclude(ba => ba.Author)
                .Include(o => o.OrderItems)
                    .ThenInclude(oi => oi.Book)
                        .ThenInclude(b => b.BookCategories)
                            .ThenInclude(bc => bc.Category)
                .AsQueryable();

            if (IsStaff())
            {
                query = ApplyFilter(query, search);
            }
            else
            {
                var currentUserId = GetCurrentUserId();

                if (!currentUserId.HasValue)
                    throw new UnauthorizedAccessException("User is not authenticated.");

                query = query.Where(o => o.UserId == currentUserId.Value);

                var safeSearch = new OrderSearchObject
                {
                    TotalPrice = search.TotalPrice,
                    OrderStatus = search.OrderStatus,
                    PaymentStatus = search.PaymentStatus,
                    Type = search.Type,
                    OrderBy = search.OrderBy,
                    IsDescending = search.IsDescending,
                    IncludeTotalCount = search.IncludeTotalCount,
                    Page = search.Page,
                    PageSize = search.PageSize
                };

                query = ApplyFilter(query, safeSearch);
            }

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

            var page = search.Page < 1 ? 1 : search.Page;
            var pageSize = search.PageSize < 1 ? 10 : search.PageSize;

            query = query
                .Skip((page - 1) * pageSize)
                .Take(pageSize);

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
                .Include(o => o.StatusChangedByUser)
                .Include(o => o.OrderItems)
                    .ThenInclude(oi => oi.Book)
                        .ThenInclude(b => b.BookAuthors)
                            .ThenInclude(ba => ba.Author)
                .Include(o => o.OrderItems)
                    .ThenInclude(oi => oi.Book)
                        .ThenInclude(b => b.BookCategories)
                            .ThenInclude(bc => bc.Category)
                .FirstOrDefaultAsync(o => o.Id == id);

            if (order == null)
                throw new KeyNotFoundException("Order not found.");

            EnsureCanAccessOrder(order);

            return MapToResponse(order);
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
                ExpiresAt = order.ExpiresAt,
                StatusChangedByName =
                order.StatusChangedByUser != null
                    ? $"{order.StatusChangedByUser.FirstName} {order.StatusChangedByUser.LastName}"
                    : null,
                StatusChangedAt = order.StatusChangedAt,
                CancellationReason = order.CancellationReason,

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
                    IsPdfPurchase = oi.IsPdfPurchase,
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
            EnsureUserAuthenticated();

            var currentUserId = GetCurrentUserId()!.Value;

            if (request.OrderItems == null || !request.OrderItems.Any())
                throw new InvalidOperationException("Narudžba mora sadržavati barem jednu knjigu.");

            await ValidatePdfPurchaseAsync(request, currentUserId);

            var bookIds = request.OrderItems
                .Select(x => x.BookId)
                .Distinct()
                .ToList();

            var books = await _context.Books
                .Where(x => bookIds.Contains(x.Id))
                .ToListAsync();

            if (books.Count != bookIds.Count)
                throw new InvalidOperationException("Jedna ili više knjiga ne postoji.");

            var now = DateTime.UtcNow;

            var entity = new Order
            {
                UserId = currentUserId,
                OrderDate = now,
                CreatedAt = now,
                Type = request.Type,
                OrderStatus = OrderStatus.Pending,
                PaymentStatus = PaymentStatus.Unpaid,
                ExpiresAt = request.Type == OrderType.Purchase
                    ? now.AddDays(7)
                    : now.AddDays(2),
                OrderItems = request.OrderItems.Select(item =>
                {
                    var book = books.First(x => x.Id == item.BookId);

                    return new OrderItem
                    {
                        BookId = item.BookId,
                        Quantity = item.Quantity,
                        UnitPrice = (decimal)book.Price,
                        IsPdfPurchase = item.IsPdfPurchase
                    };
                }).ToList()
            };

            entity.TotalPrice = entity.OrderItems
                .Sum(x => x.UnitPrice * x.Quantity);

            _context.Orders.Add(entity);

            await _context.SaveChangesAsync();

            await _notificationService.CreateAsync(
                entity.UserId,
                entity.Type == OrderType.Reservation
                ? "Rezervacija"
                : "Narudžba",
                entity.Type == OrderType.Reservation
                ? "Vaša rezervacija je uspješno kreirana."
                : "Vaša narudžba je uspješno kreirana."
                ); 

            var full = await GetByIdAsync(entity.Id);

            return full ?? MapToResponse(entity);

        }

        public override async Task<OrderResponse?> UpdateAsync(int id, OrderUpdateRequest request)
        {
            EnsureUserAuthenticated();
            EnsureStaff();

            var entity = await _context.Orders
                .Include(o => o.OrderItems)
                .FirstOrDefaultAsync(o => o.Id == id);

            if (entity == null)
                throw new KeyNotFoundException("Order not found.");

            var oldStatus = entity.OrderStatus;
            var oldPaymentStatus = entity.PaymentStatus;

            ValidateOrderStatusTransition(oldStatus, request.OrderStatus);
            ValidatePaymentStatusTransition(oldPaymentStatus, request.PaymentStatus);

            if (request.OrderStatus == OrderStatus.Cancelled && string.IsNullOrWhiteSpace(request.Reason))
            {
                throw new UserException("Razlog otkazivanja je obavezan.", 400);
            }

            entity.OrderStatus = request.OrderStatus;
            entity.PaymentStatus = request.PaymentStatus;

            entity.StatusChangedByUserId = GetCurrentUserId();
            entity.StatusChangedAt = DateTime.UtcNow;

            if (request.OrderStatus == OrderStatus.Cancelled)
            {
                entity.CancellationReason = request.Reason;
            }

            if (oldStatus != OrderStatus.Completed &&
                entity.OrderStatus == OrderStatus.Completed)
            {
                await AddPdfBooksToUserBooksAsync(entity);
            }

            await _context.SaveChangesAsync();

            if (oldStatus != entity.OrderStatus)
            {
                string message;

                if (entity.OrderStatus == OrderStatus.Cancelled)
                {
                    message =
                        $"Vaša narudžba je odbijena. Razlog: {entity.CancellationReason}";
                }
                else
                {
                    message =
                        $"Status vaše narudžbe je promijenjen u {entity.OrderStatus}.";
                }

                await _notificationService.CreateAsync(
                    entity.UserId,
                    entity.Type == OrderType.Reservation
                        ? "Rezervacija"
                        : "Narudžba",
                    message
                );
            }

            var full = await GetByIdAsync(entity.Id);
            return full ?? MapToResponse(entity);
        }

        public override async Task<bool> DeleteAsync(int id)
        {
            EnsureUserAuthenticated();

            var entity = await _context.Orders.FindAsync(id);
            if (entity == null)
                throw new KeyNotFoundException("Order not found.");

            EnsureCanAccessOrder(entity);

            _context.Orders.Remove(entity);
            await _context.SaveChangesAsync();

            return true;
        }

        public async Task<OrderResponse?> CancelAsync(int id)
        {
            EnsureUserAuthenticated();

            var entity = await _context.Orders
                .Include(o => o.OrderItems)
                .Include(o => o.User)
                .FirstOrDefaultAsync(o => o.Id == id);

            if (entity == null)
                throw new KeyNotFoundException("Order not found.");

            EnsureCanAccessOrder(entity);

            if (entity.OrderStatus == OrderStatus.Completed)
                throw new InvalidOperationException("Završena narudžba se ne može otkazati.");

            if (entity.OrderStatus == OrderStatus.Cancelled)
                throw new InvalidOperationException("Narudžba je već otkazana.");

            // zabraniti otkazivanje online plaćenih narudžbi
            if (entity.PaymentStatus == PaymentStatus.Paid)
                throw new InvalidOperationException("Online plaćene narudžbe nije moguće otkazati putem aplikacije.");

            entity.OrderStatus = OrderStatus.Cancelled;

            await _context.SaveChangesAsync();

            await _notificationService.CreateAsync(
                entity.UserId,
                entity.Type == OrderType.Reservation
                    ? "Rezervacija"
                    : "Narudžba",
                entity.Type == OrderType.Reservation
                    ? "Vaša rezervacija je otkazana."
                    : "Vaša narudžba je otkazana."
            );

            return await GetByIdAsync(id);
        }

        public async Task<OrderReportResponse> GetReportAsync(OrderReportRequest request)
        {
            request ??= new OrderReportRequest();

            var query = _context.Orders.AsQueryable();

            if (request.DateFrom.HasValue)
                query = query.Where(o => o.OrderDate >= request.DateFrom.Value);

            if (request.DateTo.HasValue)
                query = query.Where(o => o.OrderDate <= request.DateTo.Value);

            return new OrderReportResponse
            {
                TotalOrders = await query.CountAsync(),

                CompletedOrders = await query.CountAsync(o =>
                    o.OrderStatus == OrderStatus.Completed),

                CancelledOrders = await query.CountAsync(o =>
                    o.OrderStatus == OrderStatus.Cancelled),

                PaidOrders = await query.CountAsync(o =>
                    o.PaymentStatus == PaymentStatus.Paid),

                PurchaseOrders = await query.CountAsync(o =>
                    o.Type == OrderType.Purchase),

                ReservationOrders = await query.CountAsync(o =>
                    o.Type == OrderType.Reservation),

                PdfPurchases = await query
                    .SelectMany(o => o.OrderItems)
                    .Where(i => i.IsPdfPurchase)
                    .SumAsync(i => (int?)i.Quantity) ?? 0,

                HardcopyPurchases = await query
                    .SelectMany(o => o.OrderItems)
                    .Where(i => !i.IsPdfPurchase)
                    .SumAsync(i => (int?)i.Quantity) ?? 0,

                TotalRevenue = await query
                    .Where(o => o.PaymentStatus == PaymentStatus.Paid)
                    .SumAsync(o => (decimal?)o.TotalPrice) ?? 0
            };
        }
    }
}