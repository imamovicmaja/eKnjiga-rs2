using eKnjiga.Services.Database;
using Microsoft.EntityFrameworkCore;
using System.Collections.Generic;
using System.Threading.Tasks;
using eKnjiga.Model.Responses;
using eKnjiga.Model.Requests;
using eKnjiga.Model.SearchObjects;
using System.Linq;
using System;
using System.Security.Cryptography;
using System.Collections.Generic;
using eKnjiga.Model.Messages;   
using eKnjiga.Services.Messaging;
using Microsoft.AspNetCore.Http;

namespace eKnjiga.Services
{
    public class UserService : IUserService
    {
        private readonly eKnjigaDbContext _context;
        private const int SaltSize = 16;
        private const int KeySize = 32;
        private const int Iterations = 10000;
        private readonly IRoleService _roleService;
        private readonly IEmailQueue _emailQueue;

        public UserService(eKnjigaDbContext context, IRoleService roleService, IEmailQueue emailQueue)
        {
            _context = context;
            _roleService = roleService;
            _emailQueue = emailQueue;
        }

        protected IQueryable<User> ApplyFilter(IQueryable<User> query, UserSearchObject search)
        {
            if (!string.IsNullOrEmpty(search.FirstName))
                query = query.Where(b => b.FirstName.Contains(search.FirstName));

            if (!string.IsNullOrEmpty(search.LastName))
                query = query.Where(b => b.LastName.Contains(search.LastName));
            
            if (!string.IsNullOrEmpty(search.Username))
                query = query.Where(b => b.Username.Contains(search.Username));

            if (!string.IsNullOrEmpty(search.Email))
                query = query.Where(b => b.Email.Contains(search.Email));

            if (search.RoleId.HasValue)
                query = query.Where(u => u.RoleId == search.RoleId.Value);
                
            return query;
        }

        public async Task<PagedResult<UserResponse>> GetAsync(UserSearchObject search)
        {
            var query = _context.Users
                .Include(u => u.Role)
                .Include(u => u.City)
                    .ThenInclude(c => c.Country)
                .Include(a => a.UserBooks).ThenInclude(ba => ba.Book).ThenInclude(b => b.BookCategories).ThenInclude(bc => bc.Category)
                .Include(a => a.UserBooks).ThenInclude(ba => ba.Book).ThenInclude(b => b.BookAuthors).ThenInclude(bc => bc.Author)
                .AsQueryable();

            query = ApplyFilter(query, search);

            if (!string.IsNullOrEmpty(search.Username))
                query = query.Where(u => u.Username.Contains(search.Username));

            if (!string.IsNullOrEmpty(search.Email))
                query = query.Where(u => u.Email.Contains(search.Email));

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

            var users = await query.ToListAsync();

            return new PagedResult<UserResponse>
            {
                Items = users.Select(MapToResponse).ToList(),
                TotalCount = totalCount
            };
        }


        public async Task<UserResponse?> GetByIdAsync(int id)
        {
            var user = await _context.Users
                .Include(u => u.Role)
                .Include(u => u.City)
                    .ThenInclude(c => c.Country)
                .Include(a => a.UserBooks).ThenInclude(ba => ba.Book).ThenInclude(b => b.BookCategories).ThenInclude(bc => bc.Category)
                .Include(a => a.UserBooks).ThenInclude(ba => ba.Book).ThenInclude(b => b.BookAuthors).ThenInclude(bc => bc.Author)
                .FirstOrDefaultAsync(u => u.Id == id);

            return user != null ? MapToResponse(user) : null;
        }

        private string HashPassword(string password, out byte[] salt)
        {
            salt = new byte[SaltSize];
            using (var rng = new RNGCryptoServiceProvider())
            {
                rng.GetBytes(salt);
            }

            using (var pbkdf2 = new Rfc2898DeriveBytes(password, salt, Iterations))
            {
                return Convert.ToBase64String(pbkdf2.GetBytes(KeySize));
            }
        }

        public async Task<UserResponse> CreateAsync(UserUpsertRequest request)
        {
            if (await _context.Users.AnyAsync(u => u.Email == request.Email))
                throw new InvalidOperationException("Korisnik s ovom email adresom već postoji.");

            if (await _context.Users.AnyAsync(u => u.Username == request.Username))
                throw new InvalidOperationException("Korisnik s ovim korisničkim imenom već postoji.");
            
            var user = new User
            {
                FirstName = request.FirstName,
                LastName = request.LastName,
                Email = request.Email,
                Username = request.Username,
                PhoneNumber = request.PhoneNumber,
                BirthDate = request.BirthDate,
                Gender = request.Gender,
                CityId = request.CityId,
                RoleId = request.RoleId,
                CreatedAt = DateTime.UtcNow
            };

            if (!string.IsNullOrEmpty(request.Password))
            {
                byte[] salt;
                user.PasswordHash = HashPassword(request.Password, out salt);
                user.PasswordSalt = Convert.ToBase64String(salt);
            }

            _context.Users.Add(user);
            await _context.SaveChangesAsync();

            await _emailQueue.EnqueueAsync(EmailTemplates.Welcome(user));

            return await GetByIdAsync(user.Id) ?? throw new InvalidOperationException("Kreiranje korisnika nije uspjelo.");
        }

        public async Task<UserResponse?> UpdateAsync(int id, UserUpsertRequest request)
        {
            var user = await _context.Users.FindAsync(id);
            if (user == null)
                return null;

            if (await _context.Users.AnyAsync(u => u.Email == request.Email && u.Id != id))
                throw new InvalidOperationException("Korisnik s ovom email adresom već postoji.");

            if (await _context.Users.AnyAsync(u => u.Username == request.Username && u.Id != id))
                throw new InvalidOperationException("Korisnik s ovim korisničkim imenom već postoji.");

            user.FirstName = request.FirstName;
            user.LastName = request.LastName;
            user.Email = request.Email;
            user.Username = request.Username;
            user.PhoneNumber = request.PhoneNumber;
            user.BirthDate = request.BirthDate;
            user.Gender = request.Gender;
            user.CityId = request.CityId;
            user.RoleId = request.RoleId;

            if (!string.IsNullOrEmpty(request.Password))
            {
                byte[] salt;
                user.PasswordHash = HashPassword(request.Password, out salt);
                user.PasswordSalt = Convert.ToBase64String(salt);
            }

            await _context.SaveChangesAsync();
            return await GetByIdAsync(user.Id);
        }

        public async Task<bool> DeleteAsync(int id)
        {
            var user = await _context.Users.FindAsync(id);
            if (user == null)
                return false;

            _context.Users.Remove(user);
            await _context.SaveChangesAsync();
            return true;
        }

        private UserResponse MapToResponse(User user)
        {
            return new UserResponse
            {
                Id = user.Id,
                FirstName = user.FirstName,
                LastName = user.LastName,
                Email = user.Email,
                Username = user.Username,
                PhoneNumber = user.PhoneNumber,
                CreatedAt = user.CreatedAt,
                BirthDate = user.BirthDate,
                Gender = user.Gender,
                ProfileImage = string.IsNullOrEmpty(user.ProfileImage)
                ? "/images/default-user.jpg"
                : user.ProfileImage,

                Role = user.Role != null ? new RoleResponse
                {
                    Id = user.Role.Id,
                    Name = user.Role.Name,
                    Description = user.Role.Description
                } : null,

                City = user.City != null ? new CityResponse
                {
                    Id = user.City.Id,
                    Name = user.City.Name,
                    Country = user.City.Country != null ? new CountryResponse
                    {
                        Id = user.City.Country.Id,
                        Name = user.City.Country.Name,
                        Code = user.City.Country.Code
                    } : null
                } : null,

                UserBooks = user.UserBooks?
                    .Select(ub => new UserBookResponse
                    {
                        BookId = ub.BookId,
                        IsFavorite = ub.IsFavorite,

                        Book = new BookResponse
                        {
                            Id = ub.Book.Id,
                            Name = ub.Book.Name,
                            Description = ub.Book.Description,
                            Price = ub.Book.Price,
                            CoverImage = ub.Book.CoverImage,
                            Rating = ub.Book.Rating,
                            RatingCount = ub.Book.RatingCount,
                            CreatedAt = ub.Book.CreatedAt,

                            Authors = ub.Book.BookAuthors?
                                .Select(ba => new AuthorResponse
                                {
                                    Id = ba.Author.Id,
                                    FirstName = ba.Author.FirstName,
                                    LastName = ba.Author.LastName
                                })
                                .ToList() ?? new List<AuthorResponse>(),

                            Categories = ub.Book.BookCategories?
                                .Select(bc => new CategoryResponse
                                {
                                    Id = bc.Category.Id,
                                    Name = bc.Category.Name
                                })
                                .ToList() ?? new List<CategoryResponse>()
                        }
                    })
                    .ToList() ?? new List<UserBookResponse>()
            };
        }

        public async Task<UserResponse?> AuthenticateAsync(UserLoginRequest request)
        {
            var user = await _context.Users
                .Include(u => u.Role)
                .Include(u => u.City)
                .FirstOrDefaultAsync(u => u.Username == request.Username);

            if (user == null)
                return null;

            if (!VerifyPassword(request.Password!, user.PasswordHash, user.PasswordSalt))
                return null;

            return MapToResponse(user);
        }

        private bool VerifyPassword(string password, string passwordHash, string passwordSalt)
        {
            var salt = Convert.FromBase64String(passwordSalt);
            var hash = Convert.FromBase64String(passwordHash);
            var hashBytes = new Rfc2898DeriveBytes(password, salt, Iterations).GetBytes(KeySize);
            return hash.SequenceEqual(hashBytes);
        }

        public async Task<UserResponse> Register(UserUpsertRequest request)
        {
            if (await _context.Users.AnyAsync(u => u.Email == request.Email))
                throw new InvalidOperationException("Korisnik s ovom email adresom već postoji.");

            if (await _context.Users.AnyAsync(u => u.Username == request.Username))
                throw new InvalidOperationException("Korisnik s ovim korisničkim imenom već postoji.");

            var userRole = await _roleService.GetByNameAsync("user");

            var user = new User
            {
                FirstName = request.FirstName,
                LastName = request.LastName,
                Email = request.Email,
                Username = request.Username,
                PhoneNumber = request.PhoneNumber,
                BirthDate = request.BirthDate,
                Gender = request.Gender,
                CityId = request.CityId,
                RoleId = userRole.Id,
                CreatedAt = DateTime.UtcNow
            };

            if (!string.IsNullOrEmpty(request.Password))
            {
                byte[] salt;
                user.PasswordHash = HashPassword(request.Password, out salt);
                user.PasswordSalt = Convert.ToBase64String(salt);
            }

            _context.Users.Add(user);
            await _context.SaveChangesAsync();

            await _emailQueue.EnqueueAsync(EmailTemplates.Welcome(user));

            return await GetByIdAsync(user.Id) ?? throw new InvalidOperationException("Kreiranje korisnika nije uspjelo.");
        }

        private void DeleteOldProfileImage(string? relativePath)
        {
            if (string.IsNullOrWhiteSpace(relativePath))
                return;

            if (relativePath.Equals("/images/default-user.jpg", StringComparison.OrdinalIgnoreCase))
                return;

            var trimmedPath = relativePath.TrimStart('/');
            var fullPath = Path.Combine(
                Directory.GetCurrentDirectory(),
                "wwwroot",
                trimmedPath.Replace('/', Path.DirectorySeparatorChar)
            );

            if (File.Exists(fullPath))
            {
                File.Delete(fullPath);
            }
        }
        private async Task<string> SaveProfileImageAsync(IFormFile file)
        {
            var folder = Path.Combine(
                Directory.GetCurrentDirectory(),
                "wwwroot",
                "images",
                "users"
            );

            if (!Directory.Exists(folder))
                Directory.CreateDirectory(folder);

            var fileName = $"{Guid.NewGuid()}{Path.GetExtension(file.FileName).ToLower()}";
            var fullPath = Path.Combine(folder, fileName);

            using (var stream = new FileStream(fullPath, FileMode.Create))
            {
                await file.CopyToAsync(stream);
            }

            return $"/images/users/{fileName}";
        }

        public async Task<UserResponse?> UpdateProfileImageAsync(int id, IFormFile file)
        {
            var user = await _context.Users.FirstOrDefaultAsync(x => x.Id == id && !x.IsDeleted);
            if (user == null)
                return null;

            if (file == null || file.Length == 0)
                throw new InvalidOperationException("Slika nije odabrana.");

            DeleteOldProfileImage(user.ProfileImage);

            var imagePath = await SaveProfileImageAsync(file);
            user.ProfileImage = imagePath;

            await _context.SaveChangesAsync();

            return await GetByIdAsync(id);
        }

        public async Task SetFavoriteAsync(int userId, int bookId, bool isFavorite)
        {
            var userBook = await _context.UserBooks
                .FirstOrDefaultAsync(x => x.UserId == userId && x.BookId == bookId);

            if (userBook == null)
                throw new KeyNotFoundException("Knjiga nije pronađena u korisnikovim knjigama.");

            userBook.IsFavorite = isFavorite;

            await _context.SaveChangesAsync();
        }

        public async Task<bool> GetFavoriteAsync(int userId, int bookId)
        {
            var userBook = await _context.UserBooks
                .FirstOrDefaultAsync(x => x.UserId == userId && x.BookId == bookId);

            if (userBook == null)
                throw new KeyNotFoundException("Knjiga nije pronađena u korisnikovim knjigama.");

            return userBook.IsFavorite;
        }

    }
}
