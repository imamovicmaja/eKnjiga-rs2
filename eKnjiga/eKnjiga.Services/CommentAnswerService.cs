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
    public class CommentAnswerService : BaseCRUDService<CommentAnswerResponse, CommentAnswerSearchObject, Database.CommentAnswer, CommentAnswerUpsertRequest, CommentAnswerUpsertRequest>, ICommentAnswerService
    {
        public CommentAnswerService(eKnjigaDbContext context, IMapper mapper) : base(context, mapper) {}

        protected override IQueryable<CommentAnswer> ApplyFilter(IQueryable<CommentAnswer> query, CommentAnswerSearchObject search)
        {
            if (!string.IsNullOrEmpty(search.Content))
                query = query.Where(c => c.Content.Contains(search.Content));

            if (search.UserId.HasValue)
                query = query.Where(b => b.UserId == search.UserId.Value);

            if (search.ParentCommentId.HasValue)
                query = query.Where(b => b.ParentCommentId == search.ParentCommentId.Value);
            
            return query;
        }
        
        public override async Task<PagedResult<CommentAnswerResponse>> GetAsync(CommentAnswerSearchObject search)
        {
            var query = _context.CommentAnswers
                .Include(c => c.User)
                    .ThenInclude(u => u.Role)
                .Include(c => c.User)
                    .ThenInclude(u => u.City)
                        .ThenInclude(cc => cc.Country)
                .Include(c => c.ParentComment)
                    .ThenInclude(cr => cr.Reactions)
                .Include(c => c.Reactions)
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
            return new PagedResult<CommentAnswerResponse>
            {
                Items = list.Select(MapToResponse).ToList(),
                TotalCount = totalCount
            };
        }

        public override async Task<CommentAnswerResponse?> GetByIdAsync(int id)
        {
            var comment = await _context.CommentAnswers
                .Include(c => c.User)
                    .ThenInclude(u => u.Role)
                .Include(c => c.User)
                    .ThenInclude(u => u.City)
                        .ThenInclude(cc => cc.Country)
                .Include(c => c.ParentComment)
                    .ThenInclude(cr => cr.Reactions)
                .Include(c => c.Reactions)
                .FirstOrDefaultAsync(c => c.Id == id);

            return comment != null ? MapToResponse(comment) : null;
        }

        private CommentAnswerResponse MapToResponse(Database.CommentAnswer comment)
        {
            return new CommentAnswerResponse
            {
                Id = comment.Id,
                Content = comment.Content,
                CreatedAt = comment.CreatedAt,
                Likes = comment.Reactions.Count(r => r.IsLike),
                Dislikes = comment.Reactions.Count(r => !r.IsLike),
                ParentComment = comment.ParentComment != null ? new CommentResponse {
                    Id = comment.ParentComment.Id,
                    Content = comment.ParentComment.Content,
                    CreatedAt = comment.ParentComment.CreatedAt,
                    Likes = comment.ParentComment.Reactions.Count(r => r.IsLike),
                    Dislikes = comment.ParentComment.Reactions.Count(r => !r.IsLike),
                    User = comment.ParentComment.User != null ? new UserResponse
                    {
                        Id = comment.ParentComment.User.Id,
                        FirstName = comment.ParentComment.User.FirstName,
                        LastName = comment.ParentComment.User.LastName,
                        Email = comment.ParentComment.User.Email,
                        Username = comment.ParentComment.User.Username,
                        PhoneNumber = comment.ParentComment.User.PhoneNumber,
                        CreatedAt = comment.ParentComment.User.CreatedAt,
                        BirthDate = comment.ParentComment.User.BirthDate,
                        Gender = comment.ParentComment.User.Gender,
                        Role = comment.ParentComment.User.Role != null ? new RoleResponse
                        {
                            Id = comment.ParentComment.User.Role.Id,
                            Name = comment.ParentComment.User.Role.Name,
                            Description = comment.ParentComment.User.Role.Description
                        } : null,
                        City = comment.ParentComment.User.City != null ? new CityResponse
                        {
                            Id = comment.ParentComment.User.City.Id,
                            Name = comment.ParentComment.User.City.Name,
                            Country = comment.ParentComment.User.City.Country != null ? new CountryResponse
                            {
                                Id = comment.ParentComment.User.City.Country.Id,
                                Name = comment.ParentComment.User.City.Country.Name,
                                Code = comment.ParentComment.User.City.Country.Code
                            } : null
                        } : null
                    } : null,
                } : null, 
                User = comment.User != null ? new UserResponse
                {
                    Id = comment.User.Id,
                    FirstName = comment.User.FirstName,
                    LastName = comment.User.LastName,
                    Email = comment.User.Email,
                    Username = comment.User.Username,
                    PhoneNumber = comment.User.PhoneNumber,
                    CreatedAt = comment.User.CreatedAt,
                    BirthDate = comment.User.BirthDate,
                    Gender = comment.User.Gender,
                    Role = comment.User.Role != null ? new RoleResponse
                    {
                        Id = comment.User.Role.Id,
                        Name = comment.User.Role.Name,
                        Description = comment.User.Role.Description
                    } : null,
                    City = comment.User.City != null ? new CityResponse
                    {
                        Id = comment.User.City.Id,
                        Name = comment.User.City.Name,
                        Country = comment.User.City.Country != null ? new CountryResponse
                        {
                            Id = comment.User.City.Country.Id,
                            Name = comment.User.City.Country.Name,
                            Code = comment.User.City.Country.Code
                        } : null
                    } : null
                } : null
            };
        }

        public override async Task<bool> DeleteAsync(int id)
        {
            var entity = await _context.CommentAnswers.FindAsync(id);
            if (entity == null)
                throw new Exception("Odgovor nije pronađen");

            var reactions = _context.CommentReactions
                .Where(r => r.CommentAnswerId == id);

            _context.CommentReactions.RemoveRange(reactions);
            _context.CommentAnswers.Remove(entity);

            await _context.SaveChangesAsync();
            return true;
        }

    }
}
