using Microsoft.EntityFrameworkCore;
using System;
using eKnjiga.Model.Enums;

namespace eKnjiga.Services.Database
{
    public class eKnjigaDbContext : DbContext
    {
        public eKnjigaDbContext(DbContextOptions<eKnjigaDbContext> options) : base(options) { }

        public DbSet<Author> Authors { get; set; }
        public DbSet<Book> Books { get; set; }
        public DbSet<BookAuthor> BookAuthors { get; set; }
        public DbSet<BookCategory> BookCategories { get; set; }
        public DbSet<Category> Categories { get; set; }
        public DbSet<City> Cities { get; set; }
        public DbSet<Country> Countries { get; set; }
        public DbSet<Comment> Comments { get; set; }
        public DbSet<CommentAnswer> CommentAnswers { get; set; }
        public DbSet<CommentReaction> CommentReactions { get; set; }
        public DbSet<Order> Orders { get; set; }
        public DbSet<OrderItem> OrderItems { get; set; }
        public DbSet<Review> Reviews { get; set; }
        public DbSet<Role> Roles { get; set; }
        public DbSet<User> Users { get; set; }
        public DbSet<UserBook> UserBooks { get; set; }
        public DbSet<UserReport> UserReports { get; set; }
        public DbSet<PaypalLog> PaypalLogs { get; set; }
        public DbSet<Notification> Notifications { get; set; }
        public DbSet<RevokedToken> RevokedTokens { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            var seedCreatedAt = new DateTime(2026, 3, 1, 10, 0, 0);
            var seedReviewDate = new DateTime(2026, 2, 1, 10, 0, 0);
            var seedOrderDate = new DateTime(2026, 3, 1, 12, 0, 0);

            modelBuilder.Entity<BookAuthor>().HasKey(ba => new { ba.BookId, ba.AuthorId });
            modelBuilder.Entity<BookCategory>().HasKey(bc => new { bc.BookId, bc.CategoryId });
            modelBuilder.Entity<UserBook>().HasKey(ub => new { ub.UserId, ub.BookId });

            modelBuilder.Entity<User>().HasIndex(u => u.Email).IsUnique();
            modelBuilder.Entity<User>().HasIndex(u => u.Username).IsUnique();

            modelBuilder.Entity<User>()
                .HasMany(u => u.Orders)
                .WithOne(o => o.User)
                .HasForeignKey(o => o.UserId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<User>()
                .HasMany(u => u.Reviews)
                .WithOne(r => r.User)
                .HasForeignKey(r => r.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<User>()
                .HasMany(u => u.Comments)
                .WithOne(c => c.User)
                .HasForeignKey(c => c.UserId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<UserReport>()
                .HasOne(ur => ur.UserReported)
                .WithMany()
                .HasForeignKey(ur => ur.UserReportedId)
                .OnDelete(DeleteBehavior.NoAction);

            modelBuilder.Entity<UserReport>()
                .HasOne(ur => ur.ReportedByUser)
                .WithMany()
                .HasForeignKey(ur => ur.ReportedByUserId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<Book>()
                .HasMany(b => b.OrderItems)
                .WithOne(oi => oi.Book)
                .HasForeignKey(oi => oi.BookId);

            modelBuilder.Entity<Book>()
                .HasMany(b => b.Reviews)
                .WithOne(r => r.Book)
                .HasForeignKey(r => r.BookId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<Book>()
                .HasMany(b => b.UserBooks)
                .WithOne(ub => ub.Book)
                .HasForeignKey(ub => ub.BookId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<City>()
                .HasMany(c => c.Users)
                .WithOne(u => u.City)
                .HasForeignKey(u => u.CityId)
                .OnDelete(DeleteBehavior.SetNull);

            modelBuilder.Entity<Country>()
                .HasMany(c => c.Cities)
                .WithOne(c => c.Country)
                .HasForeignKey(c => c.CountryId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<Order>()
                .Property(o => o.TotalPrice)
                .HasPrecision(18, 2);

            modelBuilder.Entity<Order>()
                .HasOne(o => o.StatusChangedByUser)
                .WithMany()
                .HasForeignKey(o => o.StatusChangedByUserId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<OrderItem>()
                .Property(o => o.UnitPrice)
                .HasPrecision(18, 2);

            modelBuilder.Entity<Comment>()
                .HasMany(c => c.Reactions)
                .WithOne(r => r.Comment)
                .HasForeignKey(r => r.CommentId)
                .OnDelete(DeleteBehavior.NoAction);

            modelBuilder.Entity<CommentAnswer>()
                .HasMany(a => a.Reactions)
                .WithOne(r => r.CommentAnswer)
                .HasForeignKey(r => r.CommentAnswerId)
                .OnDelete(DeleteBehavior.NoAction);

            modelBuilder.Entity<CommentReaction>()
                .HasIndex(r => new { r.CommentId, r.UserId })
                .IsUnique()
                .HasFilter("[CommentId] IS NOT NULL");

            modelBuilder.Entity<CommentReaction>()
                .HasIndex(r => new { r.CommentAnswerId, r.UserId })
                .IsUnique()
                .HasFilter("[CommentAnswerId] IS NOT NULL");

            modelBuilder.Entity<CommentReaction>()
                .HasOne(r => r.User)
                .WithMany()
                .HasForeignKey(r => r.UserId)
                .OnDelete(DeleteBehavior.NoAction);

            modelBuilder.Entity<PaypalLog>(e =>
            {
                e.HasKey(x => x.Id);
                e.Property(x => x.CreatedAt).HasDefaultValueSql("GETUTCDATE()");
                e.Property(x => x.Direction).HasMaxLength(16).IsRequired();
                e.Property(x => x.Operation).HasMaxLength(128).IsRequired();
                e.Property(x => x.Url).HasMaxLength(512);
                e.Property(x => x.Method).HasMaxLength(10);
                e.Property(x => x.CorrelationId).HasMaxLength(128);
                e.Property(x => x.OrderId).HasMaxLength(64);
                e.Property(x => x.CaptureId).HasMaxLength(64);
                e.Property(x => x.PayerId).HasMaxLength(64);
                e.Property(x => x.Amount).HasMaxLength(32);
                e.Property(x => x.Currency).HasMaxLength(8);
            });

            modelBuilder.Entity<Country>().HasData(
                new Country { Id = 1, Name = "Bosna i Hercegovina", Code = "BA" },
                new Country { Id = 2, Name = "Hrvatska", Code = "HR" },
                new Country { Id = 3, Name = "Srbija", Code = "RS" },
                new Country { Id = 4, Name = "Slovenija", Code = "SI" }
            );

            modelBuilder.Entity<City>().HasData(
                new City { Id = 1, Name = "Sarajevo", ZipCode = 71000, CountryId = 1 },
                new City { Id = 2, Name = "Mostar", ZipCode = 88000, CountryId = 1 },
                new City { Id = 3, Name = "Zagreb", ZipCode = 10000, CountryId = 2 },
                new City { Id = 4, Name = "Banja Luka", ZipCode = 78000, CountryId = 1 },
                new City { Id = 5, Name = "Tuzla", ZipCode = 75000, CountryId = 1 },
                new City { Id = 6, Name = "Split", ZipCode = 21000, CountryId = 2 },
                new City { Id = 7, Name = "Beograd", ZipCode = 11000, CountryId = 3 },
                new City { Id = 8, Name = "Ljubljana", ZipCode = 1000, CountryId = 4 }
            );

            modelBuilder.Entity<Role>().HasData(
                new Role { Id = 1, Name = "Admin", Description = "Administrator", CreatedAt = seedCreatedAt },
                new Role { Id = 2, Name = "User", Description = "Obični korisnik", CreatedAt = seedCreatedAt },
                new Role { Id = 3, Name = "Employee", Description = "Uposlenik knjižare", CreatedAt = seedCreatedAt }
            );

            modelBuilder.Entity<User>().HasData(
                new User
                {
                    Id = 1,
                    FirstName = "Admin",
                    LastName = "Admin",
                    Email = "admin@eknjiga.com",
                    Username = "admin",
                    PasswordHash = "9iEfXvv4hJuXR4bCipTAySrubo42fPAqOoSR4YWUlRw=",
                    PasswordSalt = "boGlc7k/fmWmOtFKPzurrg==",
                    PhoneNumber = "+38761123456",
                    BirthDate = new DateTime(2001, 1, 1),
                    Gender = "Muško",
                    CreatedAt = seedCreatedAt,
                    RoleId = 1,
                    CityId = 1,
                    IsDeleted = false
                },
                new User
                {
                    Id = 2,
                    FirstName = "Maja",
                    LastName = "Imamović",
                    Email = "maja.imamovic@eknjiga.com",
                    Username = "maja",
                    PasswordHash = "siqkBrEg8pSFz3+fw+8jJGD5wUSqBmmwZEeuma3vut4=",
                    PasswordSalt = "fltpobsWzAtZXyZshvXPtg==",
                    PhoneNumber = "061987654",
                    Gender = "Žensko",
                    BirthDate = new DateTime(2004, 1, 1),
                    CreatedAt = seedCreatedAt,
                    RoleId = 2,
                    CityId = 2,
                    IsDeleted = false
                },
                new User
                {
                    Id = 3,
                    FirstName = "Haris",
                    LastName = "Test",
                    Email = "haris@eknjiga.com",
                    Username = "haris",
                    PasswordHash = "siqkBrEg8pSFz3+fw+8jJGD5wUSqBmmwZEeuma3vut4=",
                    PasswordSalt = "fltpobsWzAtZXyZshvXPtg==",
                    PhoneNumber = "062333222",
                    Gender = "Muško",
                    BirthDate = new DateTime(2008, 1, 1),
                    CreatedAt = seedCreatedAt,
                    RoleId = 2,
                    CityId = 1,
                    IsDeleted = false
                },
                new User
                {
                    Id = 4,
                    FirstName = "user",
                    LastName = "user",
                    Email = "user@knjiga.ba",
                    Username = "user",
                    PasswordHash = "siqkBrEg8pSFz3+fw+8jJGD5wUSqBmmwZEeuma3vut4=",
                    PasswordSalt = "fltpobsWzAtZXyZshvXPtg==",
                    PhoneNumber = "+38598111222",
                    Gender = "Žensko",
                    BirthDate = new DateTime(1996, 1, 1),
                    CreatedAt = seedCreatedAt,
                    RoleId = 2,
                    CityId = 3,
                    IsDeleted = false
                },
                new User
                {
                    Id = 5,
                    FirstName = "Erdin",
                    LastName = "K.",
                    Email = "erdin@eknjiga.com",
                    Username = "erdin",
                    PasswordHash = "siqkBrEg8pSFz3+fw+8jJGD5wUSqBmmwZEeuma3vut4=",
                    PasswordSalt = "fltpobsWzAtZXyZshvXPtg==",
                    PhoneNumber = "061111111",
                    Gender = "Muško",
                    BirthDate = new DateTime(1999, 1, 1),
                    CreatedAt = seedCreatedAt,
                    RoleId = 3,
                    CityId = 4,
                    IsDeleted = false
                },
                new User
                {
                    Id = 6,
                    FirstName = "Lejla",
                    LastName = "S.",
                    Email = "lejla@eknjiga.com",
                    Username = "lejla",
                    PasswordHash = "siqkBrEg8pSFz3+fw+8jJGD5wUSqBmmwZEeuma3vut4=",
                    PasswordSalt = "fltpobsWzAtZXyZshvXPtg==",
                    PhoneNumber = "062222222",
                    Gender = "Žensko",
                    BirthDate = new DateTime(2002, 1, 1),
                    CreatedAt = seedCreatedAt,
                    RoleId = 2,
                    CityId = 5,
                    IsDeleted = false
                },
                new User
                {
                    Id = 7,
                    FirstName = "Amar",
                    LastName = "B.",
                    Email = "amar@eknjiga.com",
                    Username = "amar",
                    PasswordHash = "siqkBrEg8pSFz3+fw+8jJGD5wUSqBmmwZEeuma3vut4=",
                    PasswordSalt = "fltpobsWzAtZXyZshvXPtg==",
                    PhoneNumber = "063333333",
                    Gender = "Muško",
                    BirthDate = new DateTime(1997, 1, 1),
                    CreatedAt = seedCreatedAt,
                    RoleId = 2,
                    CityId = 6,
                    IsDeleted = false
                },
                new User
                {
                    Id = 8,
                    FirstName = "Nina",
                    LastName = "P.",
                    Email = "nina@eknjiga.rs",
                    Username = "nina",
                    PasswordHash = "siqkBrEg8pSFz3+fw+8jJGD5wUSqBmmwZEeuma3vut4=",
                    PasswordSalt = "fltpobsWzAtZXyZshvXPtg==",
                    PhoneNumber = "+38160123456",
                    Gender = "Žensko",
                    BirthDate = new DateTime(2000, 1, 1),
                    CreatedAt = seedCreatedAt,
                    RoleId = 2,
                    CityId = 7,
                    IsDeleted = false
                },
                new User
                {
                    Id = 9,
                    FirstName = "Tine",
                    LastName = "Z.",
                    Email = "tine@eknjiga.si",
                    Username = "tine",
                    PasswordHash = "siqkBrEg8pSFz3+fw+8jJGD5wUSqBmmwZEeuma3vut4=",
                    PasswordSalt = "fltpobsWzAtZXyZshvXPtg==",
                    PhoneNumber = "+38640111222",
                    Gender = "Muško",
                    BirthDate = new DateTime(1995, 1, 1),
                    CreatedAt = seedCreatedAt,
                    RoleId = 2,
                    CityId = 8,
                    IsDeleted = false
                },
                new User
                {
                    Id = 10,
                    FirstName = "Ivica",
                    LastName = "K.",
                    Email = "ivica@eknjiga.ba",
                    Username = "ivica",
                    PasswordHash = "siqkBrEg8pSFz3+fw+8jJGD5wUSqBmmwZEeuma3vut4=",
                    PasswordSalt = "fltpobsWzAtZXyZshvXPtg==",
                    PhoneNumber = "+38598123456",
                    Gender = "Muško",
                    BirthDate = new DateTime(1993, 1, 1),
                    CreatedAt = seedCreatedAt,
                    RoleId = 2,
                    CityId = 6,
                    IsDeleted = false
                }
            );

            modelBuilder.Entity<Category>().HasData(
                new Category { Id = 1, Name = "Programiranje" },
                new Category { Id = 2, Name = "Roman" },
                new Category { Id = 3, Name = "Naučna fantastika" },
                new Category { Id = 4, Name = "Biografija" },
                new Category { Id = 5, Name = "Ekonomija" },
                new Category { Id = 6, Name = "Krimi" }
            );

            modelBuilder.Entity<Author>().HasData(
                new Author
                {
                    Id = 1,
                    FirstName = "Marko",
                    LastName = "Maric",
                    BirthDate = new DateTime(1975, 4, 12),
                    DeathDate = null,
                    Description = "Autor stručnih knjiga o C# jeziku i .NET platformi (npr. 'Uvod u C#', 'C# Napredne teme')."
                },
                new Author
                {
                    Id = 2,
                    FirstName = "Jana",
                    LastName = "Jovic",
                    BirthDate = new DateTime(1982, 11, 5),
                    DeathDate = null,
                    Description = "Piše romane i laganu književnost, uključujući ljubavne i SF teme (npr. 'Ljetne noći', 'Zvjezdani Put')."
                },
                new Author
                {
                    Id = 3,
                    FirstName = "Elma",
                    LastName = "Hadžibegić",
                    BirthDate = new DateTime(1970, 1, 30),
                    DeathDate = null,
                    Description = "Specijalizovana za web razvoj i ASP.NET Core, autor knjiga poput 'ASP.NET Core za početnike' i 'ASP.NET Core Praksa'."
                },
                new Author
                {
                    Id = 4,
                    FirstName = "Amir",
                    LastName = "Mehić",
                    BirthDate = new DateTime(1988, 6, 18),
                    DeathDate = null,
                    Description = "Piše prozu inspirisanu Mostarom i Hercegovinom (npr. 'Tajna starog mosta', 'Mostarske priče')."
                },
                new Author
                {
                    Id = 5,
                    FirstName = "Sara",
                    LastName = "Kovač",
                    BirthDate = new DateTime(1979, 3, 9),
                    DeathDate = null,
                    Description = "Autorica romantičnih i emotivnih priča, suautor na naslovima poput 'Zvjezdani Put'."
                },
                new Author
                {
                    Id = 6,
                    FirstName = "Ivona",
                    LastName = "Ristić",
                    BirthDate = new DateTime(1985, 9, 2),
                    DeathDate = null,
                    Description = "Suautor naprednih priručnika za C# (npr. 'C# Napredne teme'), fokus na generike i napredne obrasce."
                },
                new Author
                {
                    Id = 7,
                    FirstName = "Petar",
                    LastName = "Marić",
                    BirthDate = new DateTime(1976, 2, 17),
                    DeathDate = null,
                    Description = "Pisac krimi romana, poznat po napetim pričama kao što je 'Krimi ulice'."
                },
                new Author
                {
                    Id = 8,
                    FirstName = "Nikola",
                    LastName = "Ilić",
                    BirthDate = new DateTime(1969, 7, 21),
                    DeathDate = null,
                    Description = "Autor knjiga iz oblasti ekonomije, uključujući naslov 'Uvod u ekonomiju'."
                },
                new Author
                {
                    Id = 9,
                    FirstName = "Ana",
                    LastName = "Horvat",
                    BirthDate = new DateTime(1980, 12, 3),
                    DeathDate = null,
                    Description = "Specijalizovana za biografije inovatora i preduzetnika (npr. 'Biografija inovatora')."
                },
                new Author
                {
                    Id = 10,
                    FirstName = "Tanja",
                    LastName = "Zelić",
                    BirthDate = new DateTime(1983, 5, 11),
                    DeathDate = null,
                    Description = "Piše krimi romane smještene u Hercegovinu, poput 'Zločin na Neretvi'."
                }
            );

            modelBuilder.Entity<Book>().HasData(
                new Book { Id = 1, Name = "Uvod u C#", Description = "Osnovni priručnik za C# programiranje.", Price = 29.99, Rating = 4.5, RatingCount = 2 },
                new Book { Id = 2, Name = "Ljetne noći", Description = "Ljubavni roman za ljeto.", Price = 14.99, Rating = 5.0, RatingCount = 1 },
                new Book { Id = 3, Name = "ASP.NET Core za početnike", Description = "Detaljan vodič kroz razvoj web aplikacija koristeći ASP.NET Core.", Price = 34.99, Rating = 4.0, RatingCount = 1 },
                new Book { Id = 4, Name = "Tajna starog mosta", Description = "Historijska drama smještena u Mostaru.", Price = 19.99, Rating = 4.8, RatingCount = 3 },
                new Book { Id = 5, Name = "Zvjezdani Put", Description = "Naučna fantastika s elementima drame.", Price = 24.99, Rating = 5.0, RatingCount = 2 },
                new Book { Id = 6, Name = "C# Napredne teme", Description = "Generici, LINQ, EF Core i napredni obrasci.", Price = 39.99, Rating = 4.7, RatingCount = 3 },
                new Book { Id = 7, Name = "Mostarske priče", Description = "Kratke priče inspirisane Hercegovinom.", Price = 12.49, Rating = 4.2, RatingCount = 2 },
                new Book { Id = 8, Name = "Krimi ulice", Description = "Napeti krimi roman.", Price = 21.50, Rating = 4.6, RatingCount = 4 },
                new Book { Id = 9, Name = "Uvod u ekonomiju", Description = "Osnove mikro i makroekonomije.", Price = 17.90, Rating = 4.1, RatingCount = 2 },
                new Book { Id = 10, Name = "Biografija inovatora", Description = "Put od ideje do proizvoda.", Price = 18.99, Rating = 4.4, RatingCount = 3 },
                new Book { Id = 11, Name = "ASP.NET Core Praksa", Description = "Praktični primjeri, API, identity i deploy.", Price = 36.00, Rating = 4.8, RatingCount = 5 },
                new Book { Id = 12, Name = "Zločin na Neretvi", Description = "Kriminalistički roman smješten u Mostar.", Price = 22.00, Rating = 4.5, RatingCount = 2 }
            );

            modelBuilder.Entity<BookAuthor>().HasData(
                new BookAuthor { BookId = 1, AuthorId = 1 },
                new BookAuthor { BookId = 2, AuthorId = 2 },
                new BookAuthor { BookId = 3, AuthorId = 3 },
                new BookAuthor { BookId = 4, AuthorId = 4 },
                new BookAuthor { BookId = 5, AuthorId = 2 },
                new BookAuthor { BookId = 5, AuthorId = 5 },
                new BookAuthor { BookId = 6, AuthorId = 1 },
                new BookAuthor { BookId = 6, AuthorId = 6 },
                new BookAuthor { BookId = 7, AuthorId = 4 },
                new BookAuthor { BookId = 8, AuthorId = 7 },
                new BookAuthor { BookId = 9, AuthorId = 8 },
                new BookAuthor { BookId = 10, AuthorId = 9 },
                new BookAuthor { BookId = 11, AuthorId = 3 },
                new BookAuthor { BookId = 12, AuthorId = 10 }
            );

            modelBuilder.Entity<BookCategory>().HasData(
                new BookCategory { BookId = 1, CategoryId = 1 },
                new BookCategory { BookId = 2, CategoryId = 2 },
                new BookCategory { BookId = 3, CategoryId = 1 },
                new BookCategory { BookId = 4, CategoryId = 2 },
                new BookCategory { BookId = 5, CategoryId = 2 },
                new BookCategory { BookId = 5, CategoryId = 3 },
                new BookCategory { BookId = 6, CategoryId = 1 },
                new BookCategory { BookId = 6, CategoryId = 5 },
                new BookCategory { BookId = 7, CategoryId = 2 },
                new BookCategory { BookId = 8, CategoryId = 6 },
                new BookCategory { BookId = 9, CategoryId = 5 },
                new BookCategory { BookId = 10, CategoryId = 4 },
                new BookCategory { BookId = 11, CategoryId = 1 },
                new BookCategory { BookId = 12, CategoryId = 6 }
            );

            modelBuilder.Entity<Review>().HasData(
                new Review { Id = 1, Rating = 5, BookId = 2, UserId = 2, CreatedAt = seedReviewDate },
                new Review { Id = 2, Rating = 4, BookId = 4, UserId = 2, CreatedAt = seedReviewDate },

                new Review { Id = 3, Rating = 5, BookId = 2, UserId = 3, CreatedAt = seedReviewDate },
                new Review { Id = 4, Rating = 4, BookId = 4, UserId = 3, CreatedAt = seedReviewDate },
                new Review { Id = 5, Rating = 5, BookId = 6, UserId = 3, CreatedAt = seedReviewDate },
                new Review { Id = 6, Rating = 4, BookId = 11, UserId = 3, CreatedAt = seedReviewDate },

                new Review { Id = 7, Rating = 5, BookId = 2, UserId = 1, CreatedAt = seedReviewDate },
                new Review { Id = 8, Rating = 4, BookId = 4, UserId = 1, CreatedAt = seedReviewDate },
                new Review { Id = 9, Rating = 5, BookId = 11, UserId = 1, CreatedAt = seedReviewDate },
                new Review { Id = 10, Rating = 4, BookId = 6, UserId = 1, CreatedAt = seedReviewDate },

                new Review { Id = 11, Rating = 4, BookId = 2, UserId = 4, CreatedAt = seedReviewDate },
                new Review { Id = 12, Rating = 5, BookId = 4, UserId = 4, CreatedAt = seedReviewDate },
                new Review { Id = 13, Rating = 5, BookId = 6, UserId = 4, CreatedAt = seedReviewDate },
                new Review { Id = 14, Rating = 5, BookId = 11, UserId = 4, CreatedAt = seedReviewDate },

                new Review { Id = 15, Rating = 5, BookId = 5, UserId = 1, CreatedAt = seedReviewDate },
                new Review { Id = 16, Rating = 5, BookId = 5, UserId = 3, CreatedAt = seedReviewDate },
                new Review { Id = 17, Rating = 4, BookId = 5, UserId = 4, CreatedAt = seedReviewDate }
            );

            modelBuilder.Entity<Comment>().HasData(
                new Comment { Id = 1, Content = "Odlična knjiga!", CreatedAt = seedCreatedAt, UserId = 2 },
                new Comment { Id = 2, Content = "Preporučujem svima!", CreatedAt = seedCreatedAt, UserId = 1 },
                new Comment { Id = 3, Content = "Zanimljiva knjiga o Mostaru.", CreatedAt = seedCreatedAt, UserId = 3 },
                new Comment { Id = 4, Content = "Oduševljena sam pričom u 'Zvjezdani Put'!", CreatedAt = seedCreatedAt, UserId = 4 },
                new Comment { Id = 5, Content = "Ljetne noći su me raznježile!", CreatedAt = seedCreatedAt, UserId = 1 },

                new Comment { Id = 6, Content = "Odlična nadogradnja C# znanja!", CreatedAt = seedCreatedAt, UserId = 5 },
                new Comment { Id = 7, Content = "Krimi je top, preporuka.", CreatedAt = seedCreatedAt, UserId = 6 },
                new Comment { Id = 8, Content = "Ekonomija – jasno i sažeto.", CreatedAt = seedCreatedAt, UserId = 7 },
                new Comment { Id = 9, Content = "Biografija mi se baš svidjela.", CreatedAt = seedCreatedAt, UserId = 8 },
                new Comment { Id = 10, Content = "ASP.NET primjerima je sve lakše.", CreatedAt = seedCreatedAt, UserId = 9 },
                new Comment { Id = 11, Content = "Mostarske priče su simpatične.", CreatedAt = seedCreatedAt, UserId = 10 },
                new Comment { Id = 12, Content = "Zločin na Neretvi je napet!", CreatedAt = seedCreatedAt, UserId = 6 }
            );

            modelBuilder.Entity<CommentAnswer>().HasData(
                new CommentAnswer { Id = 1, Content = "Slažem se, odlična knjiga!", CreatedAt = seedCreatedAt, UserId = 2, ParentCommentId = 1 },
                new CommentAnswer { Id = 2, Content = "Slažem se, preporučujem svima!", CreatedAt = seedCreatedAt, UserId = 1, ParentCommentId = 2 },
                new CommentAnswer { Id = 3, Content = "Drago mi je da ti se svidjela!", CreatedAt = seedCreatedAt, UserId = 1, ParentCommentId = 3 },
                new CommentAnswer { Id = 4, Content = "I meni je knjiga fantastična!", CreatedAt = seedCreatedAt, UserId = 2, ParentCommentId = 4 },
                new CommentAnswer { Id = 5, Content = "Baš tako, prelijepa priča!", CreatedAt = seedCreatedAt, UserId = 4, ParentCommentId = 5 },

                new CommentAnswer { Id = 6, Content = "Slažem se, odličan materijal.", CreatedAt = seedCreatedAt, UserId = 6, ParentCommentId = 6 },
                new CommentAnswer { Id = 7, Content = "I meni je krimi sjeo!", CreatedAt = seedCreatedAt, UserId = 7, ParentCommentId = 7 },
                new CommentAnswer { Id = 8, Content = "Super sažetak, hvala.", CreatedAt = seedCreatedAt, UserId = 8, ParentCommentId = 8 },
                new CommentAnswer { Id = 9, Content = "Baš inspirativno.", CreatedAt = seedCreatedAt, UserId = 9, ParentCommentId = 9 },
                new CommentAnswer { Id = 10, Content = "Odlični primjeri u knjizi.", CreatedAt = seedCreatedAt, UserId = 10, ParentCommentId = 10 },
                new CommentAnswer { Id = 11, Content = "Top priče!", CreatedAt = seedCreatedAt, UserId = 5, ParentCommentId = 11 },
                new CommentAnswer { Id = 12, Content = "Drži pažnju do kraja.", CreatedAt = seedCreatedAt, UserId = 7, ParentCommentId = 12 }
            );


            modelBuilder.Entity<UserReport>().HasData(
                new UserReport
                {
                    Id = 1,
                    Reason = "Neprimjeren komentar",
                    Status = UserReportStatus.Pending,
                    CreatedAt = seedCreatedAt,
                    UserReportedId = 2,
                    ReportedByUserId = 1
                },
                new UserReport
                {
                    Id = 2,
                    Reason = "Spam ponašanje",
                    Status = UserReportStatus.InReview,
                    CreatedAt = seedCreatedAt,
                    UserReportedId = 3,
                    ReportedByUserId = 2
                },
                new UserReport
                {
                    Id = 3,
                    Reason = "Uvredljiv sadržaj",
                    Status = UserReportStatus.Pending,
                    CreatedAt = seedCreatedAt,
                    UserReportedId = 6,
                    ReportedByUserId = 5
                },
                new UserReport
                {
                    Id = 4,
                    Reason = "Spam linkovi",
                    Status = UserReportStatus.Dismissed,
                    CreatedAt = seedCreatedAt,
                    UserReportedId = 7,
                    ReportedByUserId = 6,
                    ProcessedAt = new DateTime(2026, 3, 1, 11, 30, 0),
                    ProcessedByUserId = 1
                },
                new UserReport
                {
                    Id = 5,
                    Reason = "Trolanje",
                    Status = UserReportStatus.Resolved,
                    CreatedAt = seedCreatedAt,
                    UserReportedId = 8,
                    ReportedByUserId = 5,
                    ProcessedAt = new DateTime(2026, 3, 1, 11, 50, 0),
                    ProcessedByUserId = 1
                }
            );

            modelBuilder.Entity<CommentReaction>().HasData(
                new CommentReaction { Id = 1, CommentId = 1, UserId = 1, IsLike = true },
                new CommentReaction { Id = 2, CommentId = 1, UserId = 3, IsLike = true },
                new CommentReaction { Id = 3, CommentId = 1, UserId = 4, IsLike = true },

                new CommentReaction { Id = 4, CommentId = 2, UserId = 2, IsLike = true },
                new CommentReaction { Id = 5, CommentId = 2, UserId = 3, IsLike = false },
                new CommentReaction { Id = 6, CommentId = 2, UserId = 4, IsLike = false },
                new CommentReaction { Id = 7, CommentId = 2, UserId = 1, IsLike = true },

                new CommentReaction { Id = 10, CommentId = 3, UserId = 1, IsLike = false },
                new CommentReaction { Id = 11, CommentId = 3, UserId = 2, IsLike = false },

                new CommentReaction { Id = 12, CommentId = 4, UserId = 1, IsLike = true },
                new CommentReaction { Id = 13, CommentId = 4, UserId = 2, IsLike = true },
                new CommentReaction { Id = 14, CommentId = 4, UserId = 3, IsLike = false },
                new CommentReaction { Id = 15, CommentId = 4, UserId = 4, IsLike = true },

                new CommentReaction { Id = 16, CommentId = 5, UserId = 1, IsLike = true },
                new CommentReaction { Id = 17, CommentId = 5, UserId = 2, IsLike = false },
                new CommentReaction { Id = 18, CommentId = 5, UserId = 3, IsLike = true },
                new CommentReaction { Id = 19, CommentId = 5, UserId = 4, IsLike = true },

                new CommentReaction { Id = 20, CommentAnswerId = 1, UserId = 1, IsLike = true },
                new CommentReaction { Id = 21, CommentAnswerId = 1, UserId = 3, IsLike = true },
                new CommentReaction { Id = 22, CommentAnswerId = 2, UserId = 2, IsLike = false },
                new CommentReaction { Id = 23, CommentAnswerId = 2, UserId = 4, IsLike = true },

                new CommentReaction { Id = 24, CommentId = 6, UserId = 6, IsLike = true },
                new CommentReaction { Id = 25, CommentId = 6, UserId = 7, IsLike = true },
                new CommentReaction { Id = 26, CommentId = 7, UserId = 8, IsLike = true },
                new CommentReaction { Id = 27, CommentId = 8, UserId = 9, IsLike = true },
                new CommentReaction { Id = 28, CommentId = 9, UserId = 10, IsLike = true },
                new CommentReaction { Id = 29, CommentId = 10, UserId = 5, IsLike = true },
                new CommentReaction { Id = 30, CommentId = 11, UserId = 6, IsLike = false },
                new CommentReaction { Id = 31, CommentId = 12, UserId = 7, IsLike = true },

                new CommentReaction { Id = 32, CommentAnswerId = 6, UserId = 8, IsLike = true },
                new CommentReaction { Id = 33, CommentAnswerId = 7, UserId = 9, IsLike = true },
                new CommentReaction { Id = 34, CommentAnswerId = 8, UserId = 10, IsLike = true },
                new CommentReaction { Id = 35, CommentAnswerId = 9, UserId = 5, IsLike = true },
                new CommentReaction { Id = 36, CommentAnswerId = 10, UserId = 6, IsLike = true },
                new CommentReaction { Id = 37, CommentAnswerId = 11, UserId = 7, IsLike = false },
                new CommentReaction { Id = 38, CommentAnswerId = 12, UserId = 8, IsLike = true },
                new CommentReaction { Id = 39, CommentId = 8, UserId = 5, IsLike = true },
                new CommentReaction { Id = 40, CommentAnswerId = 7, UserId = 10, IsLike = true }
            );

            modelBuilder.Entity<Order>().HasData(
                new Order
                {
                    Id = 1,
                    OrderDate = new DateTime(2026, 3, 25, 12, 0, 0),
                    CreatedAt = new DateTime(2026, 3, 25, 12, 0, 0),
                    ExpiresAt = null,
                    TotalPrice = 14.99m,
                    OrderStatus = OrderStatus.Completed,
                    PaymentStatus = PaymentStatus.Paid,
                    Type = OrderType.Purchase,
                    UserId = 2
                },
                new Order
                {
                    Id = 2,
                    OrderDate = new DateTime(2026, 3, 29, 12, 0, 0),
                    CreatedAt = new DateTime(2026, 3, 29, 12, 0, 0),
                    ExpiresAt = new DateTime(2026, 4, 5, 12, 0, 0),
                    TotalPrice = 19.99m,
                    OrderStatus = OrderStatus.Processing,
                    PaymentStatus = PaymentStatus.Pending,
                    Type = OrderType.Purchase,
                    UserId = 3
                },
                new Order
                {
                    Id = 3,
                    OrderDate = new DateTime(2026, 3, 24, 12, 0, 0),
                    CreatedAt = new DateTime(2026, 3, 24, 12, 0, 0),
                    ExpiresAt = null,
                    TotalPrice = 24.99m,
                    OrderStatus = OrderStatus.Completed,
                    PaymentStatus = PaymentStatus.Paid,
                    Type = OrderType.Purchase,
                    UserId = 4
                },
                new Order
                {
                    Id = 4,
                    OrderDate = new DateTime(2026, 3, 23, 12, 0, 0),
                    CreatedAt = new DateTime(2026, 3, 23, 12, 0, 0),
                    ExpiresAt = null,
                    TotalPrice = 14.99m,
                    OrderStatus = OrderStatus.Completed,
                    PaymentStatus = PaymentStatus.Paid,
                    Type = OrderType.Purchase,
                    UserId = 1
                },
                new Order
                {
                    Id = 5,
                    OrderDate = new DateTime(2026, 3, 30, 10, 0, 0),
                    CreatedAt = new DateTime(2026, 3, 30, 10, 0, 0),
                    ExpiresAt = new DateTime(2026, 4, 6, 10, 0, 0),
                    TotalPrice = 52.48m,
                    OrderStatus = OrderStatus.Processing,
                    PaymentStatus = PaymentStatus.Pending,
                    Type = OrderType.Purchase,
                    UserId = 5 // uposlenik
                },
                new Order
                {
                    Id = 6,
                    OrderDate = new DateTime(2026, 3, 20, 12, 0, 0),
                    CreatedAt = new DateTime(2026, 3, 20, 12, 0, 0),
                    ExpiresAt = null,
                    TotalPrice = 21.50m,
                    OrderStatus = OrderStatus.Completed,
                    PaymentStatus = PaymentStatus.Paid,
                    Type = OrderType.Purchase,
                    UserId = 6
                },
                new Order
                {
                    Id = 7,
                    OrderDate = new DateTime(2026, 3, 18, 12, 0, 0),
                    CreatedAt = new DateTime(2026, 3, 18, 12, 0, 0),
                    ExpiresAt = null,
                    TotalPrice = 36.00m,
                    OrderStatus = OrderStatus.Completed,
                    PaymentStatus = PaymentStatus.Paid,
                    Type = OrderType.Purchase,
                    UserId = 7
                },
                new Order
                {
                    Id = 8,
                    OrderDate = new DateTime(2026, 2, 20, 12, 0, 0),
                    CreatedAt = new DateTime(2026, 2, 20, 12, 0, 0),
                    ExpiresAt = new DateTime(2026, 2, 27, 12, 0, 0),
                    TotalPrice = 34.00m,
                    OrderStatus = OrderStatus.Cancelled,
                    PaymentStatus = PaymentStatus.Unpaid,
                    Type = OrderType.Purchase,
                    UserId = 8,
                    CancellationReason = "Istekao rok za placanje.",
                    StatusChangedAt = new DateTime(2026, 2, 27, 12, 0, 0),
                    StatusChangedByUserId = 1
                },
                new Order
                {
                    Id = 9,
                    OrderDate = new DateTime(2026, 3, 15, 12, 0, 0),
                    CreatedAt = new DateTime(2026, 3, 15, 12, 0, 0),
                    ExpiresAt = null,
                    TotalPrice = 18.99m,
                    OrderStatus = OrderStatus.Completed,
                    PaymentStatus = PaymentStatus.Paid,
                    Type = OrderType.Purchase,
                    UserId = 9
                },
                new Order
                {
                    Id = 10,
                    OrderDate = new DateTime(2026, 3, 10, 12, 0, 0),
                    CreatedAt = new DateTime(2026, 3, 10, 12, 0, 0),
                    ExpiresAt = null,
                    TotalPrice = 17.90m,
                    OrderStatus = OrderStatus.Completed,
                    PaymentStatus = PaymentStatus.Paid,
                    Type = OrderType.Purchase,
                    UserId = 10
                },
                new Order
                {
                    Id = 11,
                    OrderDate = new DateTime(2026, 2, 1, 12, 0, 0),
                    CreatedAt = new DateTime(2026, 2, 1, 12, 0, 0),
                    ExpiresAt = new DateTime(2026, 2, 3, 12, 0, 0),
                    TotalPrice = 19.99m,
                    OrderStatus = OrderStatus.Cancelled,
                    PaymentStatus = PaymentStatus.Unpaid,
                    Type = OrderType.Reservation,
                    UserId = 2
                },
                new Order
                {
                    Id = 12,
                    OrderDate = new DateTime(2026, 3, 30, 12, 0, 0),
                    CreatedAt = new DateTime(2026, 3, 30, 12, 0, 0),
                    ExpiresAt = new DateTime(2026, 4, 1, 12, 0, 0),
                    TotalPrice = 39.98m,
                    OrderStatus = OrderStatus.Processing,
                    PaymentStatus = PaymentStatus.Pending,
                    Type = OrderType.Reservation,
                    UserId = 3
                },
                new Order
                {
                    Id = 13,
                    OrderDate = new DateTime(2025, 12, 1, 12, 0, 0),
                    CreatedAt = new DateTime(2025, 12, 1, 12, 0, 0),
                    ExpiresAt = null,
                    TotalPrice = 24.99m,
                    OrderStatus = OrderStatus.Completed,
                    PaymentStatus = PaymentStatus.Paid,
                    Type = OrderType.Archive,
                    UserId = 4
                },
                new Order
                {
                    Id = 14,
                    OrderDate = new DateTime(2026, 1, 15, 12, 0, 0),
                    CreatedAt = new DateTime(2026, 1, 15, 12, 0, 0),
                    ExpiresAt = null,
                    TotalPrice = 52.89m,
                    OrderStatus = OrderStatus.Completed,
                    PaymentStatus = PaymentStatus.Paid,
                    Type = OrderType.Archive,
                    UserId = 5
                }
            );

            modelBuilder.Entity<OrderItem>().HasData(

                // ===== PURCHASE =====

                // PDF
                new OrderItem { Id = 1, OrderId = 1, BookId = 2, Quantity = 1, UnitPrice = 14.99m, IsPdfPurchase = true },

                // Hard copy
                new OrderItem { Id = 2, OrderId = 2, BookId = 4, Quantity = 1, UnitPrice = 19.99m, IsPdfPurchase = false },

                // PDF
                new OrderItem { Id = 3, OrderId = 3, BookId = 5, Quantity = 1, UnitPrice = 24.99m, IsPdfPurchase = true },

                // PDF
                new OrderItem { Id = 4, OrderId = 4, BookId = 2, Quantity = 1, UnitPrice = 14.99m, IsPdfPurchase = true },

                // Hard copy
                new OrderItem { Id = 5, OrderId = 5, BookId = 6, Quantity = 1, UnitPrice = 39.99m, IsPdfPurchase = false },

                // PDF
                new OrderItem { Id = 6, OrderId = 6, BookId = 8, Quantity = 1, UnitPrice = 21.50m, IsPdfPurchase = true },

                // PDF
                new OrderItem { Id = 7, OrderId = 7, BookId = 11, Quantity = 1, UnitPrice = 36.00m, IsPdfPurchase = true },

                // Hard copy
                new OrderItem { Id = 8, OrderId = 8, BookId = 12, Quantity = 1, UnitPrice = 22.00m, IsPdfPurchase = false },

                // PDF
                new OrderItem { Id = 9, OrderId = 9, BookId = 10, Quantity = 1, UnitPrice = 18.99m, IsPdfPurchase = true },

                // PDF
                new OrderItem { Id = 10, OrderId = 10, BookId = 9, Quantity = 1, UnitPrice = 17.90m, IsPdfPurchase = true },

                // MIXED ORDERS (fizičke dodatne knjige)
                new OrderItem { Id = 11, OrderId = 5, BookId = 7, Quantity = 1, UnitPrice = 12.49m, IsPdfPurchase = false },
                new OrderItem { Id = 12, OrderId = 8, BookId = 7, Quantity = 1, UnitPrice = 12.49m, IsPdfPurchase = false },


                // ===== RESERVATION (UVJEK HARDCOPY) =====

                new OrderItem { Id = 13, OrderId = 11, BookId = 4, Quantity = 1, UnitPrice = 19.99m, IsPdfPurchase = false },

                new OrderItem { Id = 14, OrderId = 12, BookId = 2, Quantity = 1, UnitPrice = 14.99m, IsPdfPurchase = false },
                new OrderItem { Id = 15, OrderId = 12, BookId = 5, Quantity = 1, UnitPrice = 24.99m, IsPdfPurchase = false },


                // ===== ARCHIVE =====

                // PDF (arhivirane digitalne kupovine)
                new OrderItem { Id = 16, OrderId = 13, BookId = 5, Quantity = 1, UnitPrice = 24.99m, IsPdfPurchase = true },

                new OrderItem { Id = 17, OrderId = 14, BookId = 1, Quantity = 1, UnitPrice = 29.99m, IsPdfPurchase = true },

                // Hard copy (arhivirane fizičke)
                new OrderItem { Id = 18, OrderId = 14, BookId = 7, Quantity = 1, UnitPrice = 12.49m, IsPdfPurchase = false },
                new OrderItem { Id = 19, OrderId = 14, BookId = 2, Quantity = 1, UnitPrice = 10.41m, IsPdfPurchase = false }
            );

            modelBuilder.Entity<UserBook>().HasData(
                new UserBook { UserId = 2, BookId = 2, IsFavorite = false },
                new UserBook { UserId = 4, BookId = 5, IsFavorite = false },
                new UserBook { UserId = 1, BookId = 2, IsFavorite = false },
                new UserBook { UserId = 6, BookId = 8, IsFavorite = false },
                new UserBook { UserId = 7, BookId = 11, IsFavorite = false },
                new UserBook { UserId = 9, BookId = 10, IsFavorite = false },
                new UserBook { UserId = 10, BookId = 9, IsFavorite = false }
            );

            modelBuilder.Entity<Notification>()
                .HasOne(x => x.User)
                .WithMany()
                .HasForeignKey(x => x.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<Notification>()
                .Property(x => x.Title)
                .IsRequired()
                .HasMaxLength(100);

            modelBuilder.Entity<Notification>()
                .Property(x => x.Text)
                .IsRequired()
                .HasMaxLength(500);

            modelBuilder.Entity<Notification>().HasData(
                new Notification
                {
                    Id = 1,
                    UserId = 2,
                    Title = "Narudžba kreirana",
                    Text = "Vaša narudžba #1 je uspješno kreirana.",
                    CreatedAt = new DateTime(2026, 3, 25, 12, 5, 0),
                    IsRead = false
                },
                new Notification
                {
                    Id = 2,
                    UserId = 2,
                    Title = "Plaćanje uspješno",
                    Text = "Plaćanje za narudžbu #1 je uspješno evidentirano.",
                    CreatedAt = new DateTime(2026, 3, 25, 12, 10, 0),
                    IsRead = true
                },
                new Notification
                {
                    Id = 3,
                    UserId = 8,
                    Title = "Narudžba otkazana",
                    Text = "Vaša narudžba #8 je otkazana zbog isteka roka za plaćanje.",
                    CreatedAt = new DateTime(2026, 2, 27, 12, 0, 0),
                    IsRead = false
                }
            );
        }
    }
}