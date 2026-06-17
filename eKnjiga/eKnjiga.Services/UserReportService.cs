using eKnjiga.Model;
using eKnjiga.Model.Enums;
using eKnjiga.Model.Requests;
using eKnjiga.Model.Responses;
using eKnjiga.Model.SearchObjects;
using eKnjiga.Model.Constants;
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

            return user.IsInRole(RoleNames.Admin) ||
                   user.Claims.Any(c =>
                       (c.Type == ClaimTypes.Role || c.Type == "role" || c.Type == "Role") &&
                       c.Value == RoleNames.Admin);
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
                    Page = search.Page,
                    PageSize = search.PageSize
                };

                query = ApplyFilter(query, safeSearch);
            }

            query = query.OrderByDescending(r => r.CreatedAt)
             .ThenBy(r => r.Id);

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

        public async Task<UserReportResponse> CreateReportAsync(CreateUserReportRequest request)
        {
            EnsureUserAuthenticated();

            var currentUserId = GetCurrentUserId()!.Value;

            if (currentUserId == request.UserReportedId)
                throw new InvalidOperationException("Ne možete prijaviti sami sebe.");

            var reportedUserExists = await _context.Users
                .AnyAsync(u => u.Id == request.UserReportedId);

            if (!reportedUserExists)
                throw new InvalidOperationException("Prijavljeni korisnik ne postoji.");

            var report = new UserReport
            {
                Reason = request.Reason,
                Status = UserReportStatus.Pending,
                UserReportedId = request.UserReportedId,
                ReportedByUserId = currentUserId,
                ProcessedByUserId = null,
                ProcessedAt = null,
                CreatedAt = DateTime.UtcNow
            };

            _context.UserReports.Add(report);
            await _context.SaveChangesAsync();

            return await GetByIdAsync(report.Id)
                ?? throw new InvalidOperationException("Kreiranje prijave nije uspjelo.");
        }

        public async Task<UserReportResponse?> ProcessReportAsync(int id, ProcessUserReportRequest request)
        {
            EnsureUserAuthenticated();

            if (!IsAdmin())
                throw new UnauthorizedAccessException("Samo administrator može obrađivati prijave.");

            var report = await _context.UserReports.FindAsync(id);

            if (report == null)
                return null;

            report.Status = request.Status;

            if (request.Status == UserReportStatus.Resolved ||
                request.Status == UserReportStatus.Dismissed)
            {
                report.ProcessedAt = DateTime.UtcNow;
                report.ProcessedByUserId = GetCurrentUserId();
            }

            await _context.SaveChangesAsync();

            return await GetByIdAsync(report.Id);
        }
    }
}