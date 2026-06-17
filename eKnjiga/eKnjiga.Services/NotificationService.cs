using eKnjiga.Model.Responses;
using eKnjiga.Model.SearchObjects;
using eKnjiga.Services.Database;
using eKnjiga.Services.Exceptions;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace eKnjiga.Services
{
    public class NotificationService : INotificationService
    {
        private readonly eKnjigaDbContext _context;
        private readonly IHttpContextAccessor _httpContextAccessor;

        public NotificationService(
            eKnjigaDbContext context,
            IHttpContextAccessor httpContextAccessor)
        {
            _context = context;
            _httpContextAccessor = httpContextAccessor;
        }

        public async Task<PagedResult<NotificationResponse>> GetForCurrentUserAsync(NotificationSearchObject search)
        {
            search ??= new NotificationSearchObject();

            var userId = GetCurrentUserId();

            var query = _context.Notifications
                .Where(x => x.UserId == userId)
                .OrderByDescending(x => x.CreatedAt)
                .AsQueryable();

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

            var items = await query
                .Select(x => new NotificationResponse
                {
                    Id = x.Id,
                    Title = x.Title,
                    Text = x.Text,
                    CreatedAt = x.CreatedAt,
                    IsRead = x.IsRead
                })
                .ToListAsync();

            return new PagedResult<NotificationResponse>
            {
                Items = items,
                TotalCount = totalCount
            };
        }

        public async Task MarkAsReadAsync(int id)
        {
            var userId = GetCurrentUserId();

            var notification = await _context.Notifications
                .FirstOrDefaultAsync(x => x.Id == id && x.UserId == userId);

            if (notification == null)
                throw new UserException("Notifikacija nije pronađena.", 404);

            notification.IsRead = true;

            await _context.SaveChangesAsync();
        }

        public async Task CreateAsync(int userId, string title, string text)
        {
            var notification = new Notification
            {
                UserId = userId,
                Title = title,
                Text = text,
                CreatedAt = DateTime.UtcNow,
                IsRead = false
            };

            _context.Notifications.Add(notification);

            await _context.SaveChangesAsync();
        }

        private int GetCurrentUserId()
        {
            var userIdClaim = _httpContextAccessor.HttpContext?.User
                .FindFirst(ClaimTypes.NameIdentifier)?.Value;

            if (string.IsNullOrWhiteSpace(userIdClaim))
                throw new UserException("Korisnik nije autentifikovan.", 401);

            if (!int.TryParse(userIdClaim, out var userId))
                throw new UserException("Neispravan korisnički token.", 401);

            return userId;
        }

        public async Task<int> GetUnreadCountAsync()
        {
            var userId = GetCurrentUserId();

            return await _context.Notifications
                .CountAsync(x => x.UserId == userId && !x.IsRead);
        }
    }
}