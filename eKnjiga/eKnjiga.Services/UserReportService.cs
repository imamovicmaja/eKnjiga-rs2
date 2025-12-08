using eKnjiga.Model.Requests;
using eKnjiga.Model.Responses;
using eKnjiga.Model.SearchObjects;
using eKnjiga.Services.Database;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using System;
using System.Linq;
using System.Threading.Tasks;
using eKnjiga.Model.Enums;

namespace eKnjiga.Services
{
    public class UserReportService : BaseCRUDService<UserReportResponse, UserReportSearchObject, Database.UserReport, UserReportUpsertRequest, UserReportUpsertRequest>, IUserReportService
    {
        public UserReportService(eKnjigaDbContext context, IMapper mapper) : base(context, mapper) {}

        protected override IQueryable<UserReport> ApplyFilter(IQueryable<UserReport> query, UserReportSearchObject search)
        {
            if (!string.IsNullOrEmpty(search.Reason))
                query = query.Where(b => b.Reason.Contains(search.Reason));

            if (search.Status.HasValue)
                query = query.Where(b => b.Status == search.Status.Value);

            if (search.UserReportedId.HasValue)
                query = query.Where(b => b.UserReportedId == search.UserReportedId.Value);

            if (search.ReportedByUserId.HasValue)
                query = query.Where(b => b.ReportedByUserId == search.ReportedByUserId.Value);

            return query;
        }
        
        public async Task<PagedResult<UserReportResponse>> GetAsync(UserReportSearchObject search)
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
                .AsQueryable();

            query = ApplyFilter(query, search);

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

        
        public async Task<UserReportResponse?> GetByIdAsync(int id)
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
                .FirstOrDefaultAsync(u => u.Id == id);

            return userReport != null ? MapToResponse(userReport) : null;
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
                ProcessedByUser = userReport.ProcessedByUser != null ? new UserResponse
                {
                    Id = userReport.ProcessedByUser.Id,
                    FirstName = userReport.ProcessedByUser.FirstName,
                    LastName = userReport.ProcessedByUser.LastName,
                    Email = userReport.ProcessedByUser.Email,
                    Username = userReport.ProcessedByUser.Username,
                    PhoneNumber = userReport.ProcessedByUser.PhoneNumber,
                    CreatedAt = userReport.ProcessedByUser.CreatedAt,
                    BirthDate = userReport.ProcessedByUser.BirthDate,
                    Gender = userReport.ProcessedByUser.Gender,
                    Role = userReport.ProcessedByUser.Role != null ? new RoleResponse
                    {
                        Id = userReport.ProcessedByUser.Role.Id,
                        Name = userReport.ProcessedByUser.Role.Name,
                        Description = userReport.ProcessedByUser.Role.Description
                    } : null,
                    City = userReport.ProcessedByUser.City != null ? new CityResponse
                    {
                        Id = userReport.ProcessedByUser.City.Id,
                        Name = userReport.ProcessedByUser.City.Name,
                        Country = userReport.ProcessedByUser.City.Country != null ? new CountryResponse
                        {
                            Id = userReport.ProcessedByUser.City.Country.Id,
                            Name = userReport.ProcessedByUser.City.Country.Name,
                            Code = userReport.ProcessedByUser.City.Country.Code
                        } : null
                    } : null
                } : null,
                UserReported = userReport.UserReported != null ? new UserResponse
                {
                    Id = userReport.UserReported.Id,
                    FirstName = userReport.UserReported.FirstName,
                    LastName = userReport.UserReported.LastName,
                    Email = userReport.UserReported.Email,
                    Username = userReport.UserReported.Username,
                    PhoneNumber = userReport.UserReported.PhoneNumber,
                    CreatedAt = userReport.UserReported.CreatedAt,
                    BirthDate = userReport.UserReported.BirthDate,
                    Gender = userReport.UserReported.Gender,
                    Role = userReport.UserReported.Role != null ? new RoleResponse
                    {
                        Id = userReport.UserReported.Role.Id,
                        Name = userReport.UserReported.Role.Name,
                        Description = userReport.UserReported.Role.Description
                    } : null,
                    City = userReport.UserReported.City != null ? new CityResponse
                    {
                        Id = userReport.UserReported.City.Id,
                        Name = userReport.UserReported.City.Name,
                        Country = userReport.UserReported.City.Country != null ? new CountryResponse
                        {
                            Id = userReport.UserReported.City.Country.Id,
                            Name = userReport.UserReported.City.Country.Name,
                            Code = userReport.UserReported.City.Country.Code
                        } : null
                    } : null
                } : null,
                ReportedByUser = userReport.ReportedByUser != null ? new UserResponse
                {
                    Id = userReport.ReportedByUser.Id,
                    FirstName = userReport.ReportedByUser.FirstName,
                    LastName = userReport.ReportedByUser.LastName,
                    Email = userReport.ReportedByUser.Email,
                    Username = userReport.ReportedByUser.Username,
                    PhoneNumber = userReport.ReportedByUser.PhoneNumber,
                    CreatedAt = userReport.ReportedByUser.CreatedAt,
                    BirthDate = userReport.ReportedByUser.BirthDate,
                    Gender = userReport.ReportedByUser.Gender,
                    Role = userReport.ReportedByUser.Role != null ? new RoleResponse
                    {
                        Id = userReport.ReportedByUser.Role.Id,
                        Name = userReport.ReportedByUser.Role.Name,
                        Description = userReport.ReportedByUser.Role.Description
                    } : null,
                    City = userReport.ReportedByUser.City != null ? new CityResponse
                    {
                        Id = userReport.ReportedByUser.City.Id,
                        Name = userReport.ReportedByUser.City.Name,
                        Country = userReport.ReportedByUser.City.Country != null ? new CountryResponse
                        {
                            Id = userReport.ReportedByUser.City.Country.Id,
                            Name = userReport.ReportedByUser.City.Country.Name,
                            Code = userReport.ReportedByUser.City.Country.Code
                        } : null
                    } : null,
                } : null,
            };
        }

        protected override async Task BeforeUpdate(UserReport entity, UserReportUpsertRequest request)
        {
            entity.Reason = request.Reason;

            bool isClosingStatus = 
                request.Status == UserReportStatus.Resolved ||
                request.Status == UserReportStatus.Dismissed;

            if (isClosingStatus && entity.Status != request.Status)
            {
                entity.Status = request.Status;

                if (entity.ProcessedAt == null)
                    entity.ProcessedAt = DateTime.UtcNow;

                if (entity.ProcessedByUserId == null && request.ProcessedByUserId.HasValue)
                    entity.ProcessedByUserId = request.ProcessedByUserId.Value;
            } else {
                entity.Status = request.Status;
            }
        }

    }
}
