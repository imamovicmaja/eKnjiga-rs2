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
    public class CommentService : BaseCRUDService<CommentResponse, CommentSearchObject, Database.Comment, CommentUpsertRequest, CommentUpsertRequest>, ICommentService
    {
        public CommentService(eKnjigaDbContext context, IMapper mapper) : base(context, mapper) {}

        protected override IQueryable<Comment> ApplyFilter(IQueryable<Comment> query, CommentSearchObject search)
        {
            if (!string.IsNullOrEmpty(search.Content))
                query = query.Where(c => c.Content.Contains(search.Content));

            if (search.UserId.HasValue)
                query = query.Where(b => b.UserId == search.UserId.Value);
            
            return query;
        }
        
        public override async Task<PagedResult<CommentResponse>> GetAsync(CommentSearchObject search)
        {
            var query = _context.Comments
                .Include(c => c.User)
                    .ThenInclude(u => u.Role)
                .Include(c => c.User)
                    .ThenInclude(u => u.City)
                        .ThenInclude(c => c.Country)
                .Include(c => c.Replies)
                    .ThenInclude(cu => cu.User)
                .Include(c => c.Replies)
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
            return new PagedResult<CommentResponse>
            {
                Items = list.Select(MapToResponse).ToList(),
                TotalCount = totalCount
            };
        }

        public override async Task<CommentResponse?> GetByIdAsync(int id)
        {
            var comment = await _context.Comments
                .Include(c => c.User)
                    .ThenInclude(u => u.Role)
                .Include(c => c.User)
                    .ThenInclude(u => u.City)
                        .ThenInclude(c => c.Country)
                .Include(c => c.Replies)
                    .ThenInclude(cr => cr.Reactions)
                .Include(c => c.Replies)
                    .ThenInclude(cu => cu.User)
                .Include(c => c.Reactions)
                .FirstOrDefaultAsync(c => c.Id == id);

            return comment != null ? MapToResponse(comment) : null;
        }

        private CommentResponse MapToResponse(Database.Comment comment)
        {
            return new CommentResponse
            {
                Id = comment.Id,
                Content = comment.Content,
                CreatedAt = comment.CreatedAt,
                Likes = comment.Reactions.Count(r => r.IsLike),
                Dislikes = comment.Reactions.Count(r => !r.IsLike),
                Replies = comment.Replies?.Select(ca => new CommentAnswerResponse
                {
                    Id = ca.Id,
                    Content = ca.Content,
                    CreatedAt = ca.CreatedAt,
                    Likes = ca.Reactions.Count(r => r.IsLike),
                    Dislikes = ca.Reactions.Count(r => !r.IsLike),
                    User = ca.User != null ? new UserResponse
                    {
                        Id = ca.User.Id,
                        FirstName = ca.User.FirstName,
                        LastName = ca.User.LastName,
                        Email = ca.User.Email,
                        Username = ca.User.Username,
                        PhoneNumber = ca.User.PhoneNumber,
                        CreatedAt = ca.User.CreatedAt,
                        BirthDate = ca.User.BirthDate,
                        Gender = ca.User.Gender,
                        Role = ca.User.Role != null ? new RoleResponse
                        {
                            Id = ca.User.Role.Id,
                            Name = ca.User.Role.Name,
                            Description = ca.User.Role.Description
                        } : null,
                        City = ca.User.City != null ? new CityResponse
                        {
                            Id = ca.User.City.Id,
                            Name = ca.User.City.Name,
                            Country = ca.User.City.Country != null ? new CountryResponse
                            {
                                Id = ca.User.City.Country.Id,
                                Name = ca.User.City.Country.Name,
                                Code = ca.User.City.Country.Code
                            } : null
                        } : null
                    } : null
                }).ToList() ?? new List<CommentAnswerResponse>(),
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
            var comment = await _context.Comments.FindAsync(id);
            if (comment == null)
                throw new Exception("Komentar nije pronađen");

            var replies = _context.CommentAnswers
                .Where(a => a.ParentCommentId == id)
                .ToList();

            var replyIds = replies.Select(r => r.Id).ToList();
            var replyReactions = _context.CommentReactions
                .Where(r => r.CommentAnswerId != null && replyIds.Contains(r.CommentAnswerId.Value));
            _context.CommentReactions.RemoveRange(replyReactions);

            _context.CommentAnswers.RemoveRange(replies);

            var commentReactions = _context.CommentReactions
                .Where(r => r.CommentId == id);
            _context.CommentReactions.RemoveRange(commentReactions);

            _context.Comments.Remove(comment);

            await _context.SaveChangesAsync();
            return true;
        }

    }
}
