using eKnjiga.Model;
using eKnjiga.Model.Enums;
using eKnjiga.Model.Requests;
using eKnjiga.Model.Responses;
using eKnjiga.Model.SearchObjects;
using eKnjiga.Services.Database;
using MapsterMapper;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Claims;
using System.Threading.Tasks;

namespace eKnjiga.Services
{
    public class UserReportService : BaseCRUDService<UserReportResponse, UserReportSearchObject, Database.UserReport, UserReportUpsertRequest, UserReportUpsertRequest>, IUserReportService
    {
        private readonly IHttpContextAccessor _httpContextAccessor;

        public UserReportService(eKnjigaDbContext context, IMapper mapper, IHttpContextAccessor httpContextAccessor)
            : base(context, mapper)
        {
            _httpContextAccessor = httpContextAccessor;
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

            return user.IsInRole("Admin") ||
                   user.Claims.Any(c =>
                       (c.Type == ClaimTypes.Role || c.Type == "role" || c.Type == "Role") &&
                       c.Value == "Admin");
        }

        private PublicUserResponse? MapToPublicUserResponse(Database.User? user)
        {
            if (user == null)
                return null;

            return new PublicUserResponse
            {
                Id = user.Id,
                Username = user.Username,
                FirstName = user.FirstName,
                LastName = user.LastName,
                ProfileImage = string.IsNullOrEmpty(user.ProfileImage)
                ? "/images/default-user.jpg"
                : user.ProfileImage
            };
        }

        private void EnsureUserAuthenticated()
        {
            if (!GetCurrentUserId().HasValue)
                throw new UnauthorizedAccessException("User is not authenticated.");
        }

        protected override IQueryable<UserReport> ApplyFilter(IQueryable<UserReport> query, UserReportSearchObject search)
        {
            if (!string.IsNullOrEmpty(search.Reason))
                query = query.Where(r => r.Reason.Contains(search.Reason));

            if (search.Status.HasValue)
                query = query.Where(r => r.Status == search.Status.Value);

            if (search.UserReportedId.HasValue)
                query = query.Where(r => r.UserReportedId == search.UserReportedId.Value);

            if (search.ReportedByUserId.HasValue)
                query = query.Where(r => r.ReportedByUserId == search.ReportedByUserId.Value);

            return query;
        }

        public override async Task<PagedResult<UserReportResponse>> GetAsync(UserReportSearchObject search)
        {
            var query = _context.UserReports
                .Include(u => u.UserReported)
                    .ThenInclude(c => c.City)
                        .ThenInclude(cc => cc.Country)
                .Include(u => u.UserReported)
                    .ThenInclude(r => r.Role)
                .Include(u => u.ReportedByUser)
                    .ThenInclude(c => c.City)
                        .ThenInclude(cc => cc.Country)
                .Include(u => u.ReportedByUser)
                    .ThenInclude(r => r.Role)
                .Include(u => u.ProcessedByUser)
                    .ThenInclude(c => c.City)
                        .ThenInclude(cc => cc.Country)
                .Include(u => u.ProcessedByUser)
                    .ThenInclude(r => r.Role)
                .AsQueryable();

            if (IsAdmin())
            {
                query = ApplyFilter(query, search);
            }
            else
            {
                EnsureUserAuthenticated();
                var currentUserId = GetCurrentUserId()!.Value;

                query = query.Where(r => r.ReportedByUserId == currentUserId);

                var safeSearch = new UserReportSearchObject
                {
                    Reason = search.Reason,
                    Status = search.Status,
                    UserReportedId = search.UserReportedId,
                    IncludeTotalCount = search.IncludeTotalCount,
                    RetrieveAll = search.RetrieveAll,
                    Page = search.Page,
                    PageSize = search.PageSize
                };

                query = ApplyFilter(query, safeSearch);
            }

            int? totalCount = null;
            if (search.IncludeTotalCount)
                totalCount = await query.CountAsync();

            if (!search.RetrieveAll)
            {
                if (search.Page.HasValue)
                    query = query.Skip(search.Page.Value * search.PageSize.Value);

                if (search.PageSize.HasValue)
                    query = query.Take(search.PageSize.Value);
            }

            var list = await query.ToListAsync();

            return new PagedResult<UserReportResponse>
            {
                Items = list.Select(MapToResponse).ToList(),
                TotalCount = totalCount
            };
        }

        public override async Task<UserReportResponse?> GetByIdAsync(int id)
        {
            var userReport = await _context.UserReports
                .Include(u => u.UserReported)
                    .ThenInclude(c => c.City)
                        .ThenInclude(cc => cc.Country)
                .Include(u => u.UserReported)
                    .ThenInclude(r => r.Role)
                .Include(u => u.ReportedByUser)
                    .ThenInclude(c => c.City)
                        .ThenInclude(cc => cc.Country)
                .Include(u => u.ReportedByUser)
                    .ThenInclude(r => r.Role)
                .Include(u => u.ProcessedByUser)
                    .ThenInclude(c => c.City)
                        .ThenInclude(cc => cc.Country)
                .Include(u => u.ProcessedByUser)
                    .ThenInclude(r => r.Role)
                .FirstOrDefaultAsync(u => u.Id == id);

            if (userReport == null)
                throw new KeyNotFoundException("User report not found.");

            if (!IsAdmin())
            {
                EnsureUserAuthenticated();
                var currentUserId = GetCurrentUserId()!.Value;

                if (userReport.ReportedByUserId != currentUserId)
                    throw new UnauthorizedAccessException("You are not allowed to access this report.");
            }

            return MapToResponse(userReport);
        }

        private UserReportResponse MapToResponse(UserReport userReport)
        {
            return new UserReportResponse
            {
                Id = userReport.Id,
                Reason = userReport.Reason,
                Status = userReport.Status,
                CreatedAt = userReport.CreatedAt,
                ProcessedAt = userReport.ProcessedAt,
                ProcessedByUser = MapToPublicUserResponse(userReport.ProcessedByUser),
                UserReported = MapToPublicUserResponse(userReport.UserReported),
                ReportedByUser = MapToPublicUserResponse(userReport.ReportedByUser)
            };
        }

        protected override async Task BeforeInsert(UserReport entity, UserReportUpsertRequest request)
        {
            EnsureUserAuthenticated();

            if (!IsAdmin())
            {
                var currentUserId = GetCurrentUserId()!.Value;

                request.ReportedByUserId = currentUserId;
                entity.ReportedByUserId = currentUserId;

                request.ProcessedByUserId = null;
                entity.ProcessedByUserId = null;

                if (request.Status != UserReportStatus.Pending)
                    request.Status = UserReportStatus.Pending;

                entity.Status = request.Status;
                entity.ProcessedAt = null;
            }

            await Task.CompletedTask;
        }

        protected override async Task BeforeUpdate(UserReport entity, UserReportUpsertRequest request)
        {
            EnsureUserAuthenticated();

            if (!IsAdmin())
                throw new UnauthorizedAccessException("Only admin can process user reports.");

            entity.Reason = request.Reason;

            bool isClosingStatus =
                request.Status == UserReportStatus.Resolved ||
                request.Status == UserReportStatus.Dismissed;

            if (isClosingStatus && entity.Status != request.Status)
            {
                entity.Status = request.Status;

                if (entity.ProcessedAt == null)
                    entity.ProcessedAt = DateTime.UtcNow;

                if (entity.ProcessedByUserId == null)
                {
                    var currentUserId = GetCurrentUserId();
                    if (currentUserId.HasValue)
                        entity.ProcessedByUserId = currentUserId.Value;
                }
            }
            else
            {
                entity.Status = request.Status;
            }
        }
    }
}