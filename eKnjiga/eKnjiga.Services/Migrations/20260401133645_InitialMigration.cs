using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace eKnjiga.Services.Migrations
{
    /// <inheritdoc />
    public partial class InitialMigration : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "Authors",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    FirstName = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    LastName = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    BirthDate = table.Column<DateTime>(type: "datetime2", nullable: true),
                    DeathDate = table.Column<DateTime>(type: "datetime2", nullable: true),
                    Description = table.Column<string>(type: "nvarchar(2000)", maxLength: 2000, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Authors", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "Books",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Name = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    Description = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: false),
                    Price = table.Column<double>(type: "float", nullable: false),
                    CoverImage = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    PdfFile = table.Column<byte[]>(type: "varbinary(max)", nullable: true),
                    Rating = table.Column<double>(type: "float", nullable: false),
                    RatingCount = table.Column<int>(type: "int", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Books", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "Categories",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Name = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Categories", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "Countries",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Name = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    Code = table.Column<string>(type: "nvarchar(4)", maxLength: 4, nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Countries", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "PaypalLogs",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "GETUTCDATE()"),
                    Direction = table.Column<string>(type: "nvarchar(16)", maxLength: 16, nullable: false),
                    Operation = table.Column<string>(type: "nvarchar(128)", maxLength: 128, nullable: false),
                    Url = table.Column<string>(type: "nvarchar(512)", maxLength: 512, nullable: true),
                    Method = table.Column<string>(type: "nvarchar(10)", maxLength: 10, nullable: true),
                    HttpStatus = table.Column<int>(type: "int", nullable: true),
                    CorrelationId = table.Column<string>(type: "nvarchar(128)", maxLength: 128, nullable: true),
                    OrderId = table.Column<string>(type: "nvarchar(64)", maxLength: 64, nullable: true),
                    CaptureId = table.Column<string>(type: "nvarchar(64)", maxLength: 64, nullable: true),
                    PayerId = table.Column<string>(type: "nvarchar(64)", maxLength: 64, nullable: true),
                    Amount = table.Column<string>(type: "nvarchar(32)", maxLength: 32, nullable: true),
                    Currency = table.Column<string>(type: "nvarchar(8)", maxLength: 8, nullable: true),
                    RequestHeaders = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    RequestBody = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    ResponseBody = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    Error = table.Column<string>(type: "nvarchar(max)", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PaypalLogs", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "Roles",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Name = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    Description = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Roles", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "BookAuthors",
                columns: table => new
                {
                    BookId = table.Column<int>(type: "int", nullable: false),
                    AuthorId = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_BookAuthors", x => new { x.BookId, x.AuthorId });
                    table.ForeignKey(
                        name: "FK_BookAuthors_Authors_AuthorId",
                        column: x => x.AuthorId,
                        principalTable: "Authors",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_BookAuthors_Books_BookId",
                        column: x => x.BookId,
                        principalTable: "Books",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "BookCategories",
                columns: table => new
                {
                    BookId = table.Column<int>(type: "int", nullable: false),
                    CategoryId = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_BookCategories", x => new { x.BookId, x.CategoryId });
                    table.ForeignKey(
                        name: "FK_BookCategories_Books_BookId",
                        column: x => x.BookId,
                        principalTable: "Books",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_BookCategories_Categories_CategoryId",
                        column: x => x.CategoryId,
                        principalTable: "Categories",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "Cities",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Name = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    ZipCode = table.Column<int>(type: "int", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    CountryId = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Cities", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Cities_Countries_CountryId",
                        column: x => x.CountryId,
                        principalTable: "Countries",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "Users",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    FirstName = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    LastName = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    Email = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    Username = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    PasswordHash = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    PasswordSalt = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    ProfileImage = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    PhoneNumber = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: true),
                    BirthDate = table.Column<DateTime>(type: "datetime2", nullable: true),
                    Gender = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: true),
                    IsDeleted = table.Column<bool>(type: "bit", nullable: false),
                    RoleId = table.Column<int>(type: "int", nullable: false),
                    CityId = table.Column<int>(type: "int", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Users", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Users_Cities_CityId",
                        column: x => x.CityId,
                        principalTable: "Cities",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.SetNull);
                    table.ForeignKey(
                        name: "FK_Users_Roles_RoleId",
                        column: x => x.RoleId,
                        principalTable: "Roles",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "Comments",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Content = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    UserId = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Comments", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Comments_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "Orders",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    OrderDate = table.Column<DateTime>(type: "datetime2", nullable: false),
                    TotalPrice = table.Column<decimal>(type: "decimal(18,2)", precision: 18, scale: 2, nullable: false),
                    OrderStatus = table.Column<int>(type: "int", nullable: false),
                    PaymentStatus = table.Column<int>(type: "int", nullable: false),
                    Type = table.Column<int>(type: "int", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    ExpiresAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    PaypalOrderId = table.Column<string>(type: "nvarchar(128)", maxLength: 128, nullable: true),
                    PaypalCaptureId = table.Column<string>(type: "nvarchar(128)", maxLength: 128, nullable: true),
                    PaypalSandbox = table.Column<bool>(type: "bit", nullable: true),
                    UserId = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Orders", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Orders_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "Reviews",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Rating = table.Column<double>(type: "float", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    BookId = table.Column<int>(type: "int", nullable: false),
                    UserId = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Reviews", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Reviews_Books_BookId",
                        column: x => x.BookId,
                        principalTable: "Books",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_Reviews_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "UserBooks",
                columns: table => new
                {
                    UserId = table.Column<int>(type: "int", nullable: false),
                    BookId = table.Column<int>(type: "int", nullable: false),
                    IsFavorite = table.Column<bool>(type: "bit", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_UserBooks", x => new { x.UserId, x.BookId });
                    table.ForeignKey(
                        name: "FK_UserBooks_Books_BookId",
                        column: x => x.BookId,
                        principalTable: "Books",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_UserBooks_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "UserReports",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Reason = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: false),
                    Status = table.Column<int>(type: "int", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    ProcessedAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    UserReportedId = table.Column<int>(type: "int", nullable: false),
                    ReportedByUserId = table.Column<int>(type: "int", nullable: false),
                    ProcessedByUserId = table.Column<int>(type: "int", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_UserReports", x => x.Id);
                    table.ForeignKey(
                        name: "FK_UserReports_Users_ProcessedByUserId",
                        column: x => x.ProcessedByUserId,
                        principalTable: "Users",
                        principalColumn: "Id");
                    table.ForeignKey(
                        name: "FK_UserReports_Users_ReportedByUserId",
                        column: x => x.ReportedByUserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_UserReports_Users_UserReportedId",
                        column: x => x.UserReportedId,
                        principalTable: "Users",
                        principalColumn: "Id");
                });

            migrationBuilder.CreateTable(
                name: "CommentAnswers",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    ParentCommentId = table.Column<int>(type: "int", nullable: true),
                    Content = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    UserId = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_CommentAnswers", x => x.Id);
                    table.ForeignKey(
                        name: "FK_CommentAnswers_Comments_ParentCommentId",
                        column: x => x.ParentCommentId,
                        principalTable: "Comments",
                        principalColumn: "Id");
                    table.ForeignKey(
                        name: "FK_CommentAnswers_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "OrderItems",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    OrderId = table.Column<int>(type: "int", nullable: false),
                    BookId = table.Column<int>(type: "int", nullable: false),
                    IsPdfPurchase = table.Column<bool>(type: "bit", nullable: false),
                    Quantity = table.Column<int>(type: "int", nullable: false),
                    UnitPrice = table.Column<decimal>(type: "decimal(18,2)", precision: 18, scale: 2, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_OrderItems", x => x.Id);
                    table.ForeignKey(
                        name: "FK_OrderItems_Books_BookId",
                        column: x => x.BookId,
                        principalTable: "Books",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_OrderItems_Orders_OrderId",
                        column: x => x.OrderId,
                        principalTable: "Orders",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "CommentReactions",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    CommentId = table.Column<int>(type: "int", nullable: true),
                    CommentAnswerId = table.Column<int>(type: "int", nullable: true),
                    UserId = table.Column<int>(type: "int", nullable: false),
                    IsLike = table.Column<bool>(type: "bit", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_CommentReactions", x => x.Id);
                    table.ForeignKey(
                        name: "FK_CommentReactions_CommentAnswers_CommentAnswerId",
                        column: x => x.CommentAnswerId,
                        principalTable: "CommentAnswers",
                        principalColumn: "Id");
                    table.ForeignKey(
                        name: "FK_CommentReactions_Comments_CommentId",
                        column: x => x.CommentId,
                        principalTable: "Comments",
                        principalColumn: "Id");
                    table.ForeignKey(
                        name: "FK_CommentReactions_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id");
                });

            migrationBuilder.InsertData(
                table: "Authors",
                columns: new[] { "Id", "BirthDate", "CreatedAt", "DeathDate", "Description", "FirstName", "LastName" },
                values: new object[,]
                {
                    { 1, new DateTime(1975, 4, 12, 0, 0, 0, 0, DateTimeKind.Unspecified), new DateTime(2026, 4, 1, 13, 36, 44, 467, DateTimeKind.Utc).AddTicks(2256), null, "Autor stručnih knjiga o C# jeziku i .NET platformi (npr. 'Uvod u C#', 'C# Napredne teme').", "Marko", "Maric" },
                    { 2, new DateTime(1982, 11, 5, 0, 0, 0, 0, DateTimeKind.Unspecified), new DateTime(2026, 4, 1, 13, 36, 44, 467, DateTimeKind.Utc).AddTicks(2260), null, "Piše romane i laganu književnost, uključujući ljubavne i SF teme (npr. 'Ljetne noći', 'Zvjezdani Put').", "Jana", "Jovic" },
                    { 3, new DateTime(1970, 1, 30, 0, 0, 0, 0, DateTimeKind.Unspecified), new DateTime(2026, 4, 1, 13, 36, 44, 467, DateTimeKind.Utc).AddTicks(2261), null, "Specijalizovana za web razvoj i ASP.NET Core, autor knjiga poput 'ASP.NET Core za početnike' i 'ASP.NET Core Praksa'.", "Elma", "Hadžibegić" },
                    { 4, new DateTime(1988, 6, 18, 0, 0, 0, 0, DateTimeKind.Unspecified), new DateTime(2026, 4, 1, 13, 36, 44, 467, DateTimeKind.Utc).AddTicks(2263), null, "Piše prozu inspirisanu Mostarom i Hercegovinom (npr. 'Tajna starog mosta', 'Mostarske priče').", "Amir", "Mehić" },
                    { 5, new DateTime(1979, 3, 9, 0, 0, 0, 0, DateTimeKind.Unspecified), new DateTime(2026, 4, 1, 13, 36, 44, 467, DateTimeKind.Utc).AddTicks(2265), null, "Autorica romantičnih i emotivnih priča, suautor na naslovima poput 'Zvjezdani Put'.", "Sara", "Kovač" },
                    { 6, new DateTime(1985, 9, 2, 0, 0, 0, 0, DateTimeKind.Unspecified), new DateTime(2026, 4, 1, 13, 36, 44, 467, DateTimeKind.Utc).AddTicks(2266), null, "Suautor naprednih priručnika za C# (npr. 'C# Napredne teme'), fokus na generike i napredne obrasce.", "Ivona", "Ristić" },
                    { 7, new DateTime(1976, 2, 17, 0, 0, 0, 0, DateTimeKind.Unspecified), new DateTime(2026, 4, 1, 13, 36, 44, 467, DateTimeKind.Utc).AddTicks(2267), null, "Pisac krimi romana, poznat po napetim pričama kao što je 'Krimi ulice'.", "Petar", "Marić" },
                    { 8, new DateTime(1969, 7, 21, 0, 0, 0, 0, DateTimeKind.Unspecified), new DateTime(2026, 4, 1, 13, 36, 44, 467, DateTimeKind.Utc).AddTicks(2269), null, "Autor knjiga iz oblasti ekonomije, uključujući naslov 'Uvod u ekonomiju'.", "Nikola", "Ilić" },
                    { 9, new DateTime(1980, 12, 3, 0, 0, 0, 0, DateTimeKind.Unspecified), new DateTime(2026, 4, 1, 13, 36, 44, 467, DateTimeKind.Utc).AddTicks(2270), null, "Specijalizovana za biografije inovatora i preduzetnika (npr. 'Biografija inovatora').", "Ana", "Horvat" },
                    { 10, new DateTime(1983, 5, 11, 0, 0, 0, 0, DateTimeKind.Unspecified), new DateTime(2026, 4, 1, 13, 36, 44, 467, DateTimeKind.Utc).AddTicks(2272), null, "Piše krimi romane smještene u Hercegovinu, poput 'Zločin na Neretvi'.", "Tanja", "Zelić" }
                });

            migrationBuilder.InsertData(
                table: "Books",
                columns: new[] { "Id", "CoverImage", "CreatedAt", "Description", "Name", "PdfFile", "Price", "Rating", "RatingCount" },
                values: new object[,]
                {
                    { 1, null, new DateTime(2026, 4, 1, 13, 36, 44, 467, DateTimeKind.Utc).AddTicks(2298), "Osnovni priručnik za C# programiranje.", "Uvod u C#", null, 29.989999999999998, 4.5, 2 },
                    { 2, null, new DateTime(2026, 4, 1, 13, 36, 44, 467, DateTimeKind.Utc).AddTicks(2309), "Ljubavni roman za ljeto.", "Ljetne noći", null, 14.99, 5.0, 1 },
                    { 3, null, new DateTime(2026, 4, 1, 13, 36, 44, 467, DateTimeKind.Utc).AddTicks(2311), "Detaljan vodič kroz razvoj web aplikacija koristeći ASP.NET Core.", "ASP.NET Core za početnike", null, 34.990000000000002, 4.0, 1 },
                    { 4, null, new DateTime(2026, 4, 1, 13, 36, 44, 467, DateTimeKind.Utc).AddTicks(2312), "Historijska drama smještena u Mostaru.", "Tajna starog mosta", null, 19.989999999999998, 4.7999999999999998, 3 },
                    { 5, null, new DateTime(2026, 4, 1, 13, 36, 44, 467, DateTimeKind.Utc).AddTicks(2314), "Naučna fantastika s elementima drame.", "Zvjezdani Put", null, 24.989999999999998, 5.0, 2 },
                    { 6, null, new DateTime(2026, 4, 1, 13, 36, 44, 467, DateTimeKind.Utc).AddTicks(2316), "Generici, LINQ, EF Core i napredni obrasci.", "C# Napredne teme", null, 39.990000000000002, 4.7000000000000002, 3 },
                    { 7, null, new DateTime(2026, 4, 1, 13, 36, 44, 467, DateTimeKind.Utc).AddTicks(2317), "Kratke priče inspirisane Hercegovinom.", "Mostarske priče", null, 12.49, 4.2000000000000002, 2 },
                    { 8, null, new DateTime(2026, 4, 1, 13, 36, 44, 467, DateTimeKind.Utc).AddTicks(2319), "Napeti krimi roman.", "Krimi ulice", null, 21.5, 4.5999999999999996, 4 },
                    { 9, null, new DateTime(2026, 4, 1, 13, 36, 44, 467, DateTimeKind.Utc).AddTicks(2320), "Osnove mikro i makroekonomije.", "Uvod u ekonomiju", null, 17.899999999999999, 4.0999999999999996, 2 },
                    { 10, null, new DateTime(2026, 4, 1, 13, 36, 44, 467, DateTimeKind.Utc).AddTicks(2322), "Put od ideje do proizvoda.", "Biografija inovatora", null, 18.989999999999998, 4.4000000000000004, 3 },
                    { 11, null, new DateTime(2026, 4, 1, 13, 36, 44, 467, DateTimeKind.Utc).AddTicks(2323), "Praktični primjeri, API, identity i deploy.", "ASP.NET Core Praksa", null, 36.0, 4.7999999999999998, 5 },
                    { 12, null, new DateTime(2026, 4, 1, 13, 36, 44, 467, DateTimeKind.Utc).AddTicks(2325), "Kriminalistički roman smješten u Mostar.", "Zločin na Neretvi", null, 22.0, 4.5, 2 }
                });

            migrationBuilder.InsertData(
                table: "Categories",
                columns: new[] { "Id", "CreatedAt", "Name" },
                values: new object[,]
                {
                    { 1, new DateTime(2026, 4, 1, 13, 36, 44, 467, DateTimeKind.Utc).AddTicks(2229), "Programiranje" },
                    { 2, new DateTime(2026, 4, 1, 13, 36, 44, 467, DateTimeKind.Utc).AddTicks(2231), "Roman" },
                    { 3, new DateTime(2026, 4, 1, 13, 36, 44, 467, DateTimeKind.Utc).AddTicks(2231), "Naučna fantastika" },
                    { 4, new DateTime(2026, 4, 1, 13, 36, 44, 467, DateTimeKind.Utc).AddTicks(2232), "Biografija" },
                    { 5, new DateTime(2026, 4, 1, 13, 36, 44, 467, DateTimeKind.Utc).AddTicks(2233), "Ekonomija" },
                    { 6, new DateTime(2026, 4, 1, 13, 36, 44, 467, DateTimeKind.Utc).AddTicks(2234), "Krimi" }
                });

            migrationBuilder.InsertData(
                table: "Countries",
                columns: new[] { "Id", "Code", "CreatedAt", "Name" },
                values: new object[,]
                {
                    { 1, "BA", new DateTime(2026, 4, 1, 13, 36, 44, 467, DateTimeKind.Utc).AddTicks(1893), "Bosna i Hercegovina" },
                    { 2, "HR", new DateTime(2026, 4, 1, 13, 36, 44, 467, DateTimeKind.Utc).AddTicks(1896), "Hrvatska" },
                    { 3, "RS", new DateTime(2026, 4, 1, 13, 36, 44, 467, DateTimeKind.Utc).AddTicks(1897), "Srbija" },
                    { 4, "SI", new DateTime(2026, 4, 1, 13, 36, 44, 467, DateTimeKind.Utc).AddTicks(1898), "Slovenija" }
                });

            migrationBuilder.InsertData(
                table: "Roles",
                columns: new[] { "Id", "CreatedAt", "Description", "Name" },
                values: new object[,]
                {
                    { 1, new DateTime(2026, 3, 1, 10, 0, 0, 0, DateTimeKind.Unspecified), "Administrator", "Admin" },
                    { 2, new DateTime(2026, 3, 1, 10, 0, 0, 0, DateTimeKind.Unspecified), "Obični korisnik", "User" },
                    { 3, new DateTime(2026, 3, 1, 10, 0, 0, 0, DateTimeKind.Unspecified), "Uposlenik knjižare", "Employee" }
                });

            migrationBuilder.InsertData(
                table: "BookAuthors",
                columns: new[] { "AuthorId", "BookId" },
                values: new object[,]
                {
                    { 1, 1 },
                    { 2, 2 },
                    { 3, 3 },
                    { 4, 4 },
                    { 2, 5 },
                    { 5, 5 },
                    { 1, 6 },
                    { 6, 6 },
                    { 4, 7 },
                    { 7, 8 },
                    { 8, 9 },
                    { 9, 10 },
                    { 3, 11 },
                    { 10, 12 }
                });

            migrationBuilder.InsertData(
                table: "BookCategories",
                columns: new[] { "BookId", "CategoryId" },
                values: new object[,]
                {
                    { 1, 1 },
                    { 2, 2 },
                    { 3, 1 },
                    { 4, 2 },
                    { 5, 2 },
                    { 5, 3 },
                    { 6, 1 },
                    { 6, 5 },
                    { 7, 2 },
                    { 8, 6 },
                    { 9, 5 },
                    { 10, 4 },
                    { 11, 1 },
                    { 12, 6 }
                });

            migrationBuilder.InsertData(
                table: "Cities",
                columns: new[] { "Id", "CountryId", "CreatedAt", "Name", "ZipCode" },
                values: new object[,]
                {
                    { 1, 1, new DateTime(2026, 4, 1, 13, 36, 44, 467, DateTimeKind.Utc).AddTicks(2103), "Sarajevo", 71000 },
                    { 2, 1, new DateTime(2026, 4, 1, 13, 36, 44, 467, DateTimeKind.Utc).AddTicks(2105), "Mostar", 88000 },
                    { 3, 2, new DateTime(2026, 4, 1, 13, 36, 44, 467, DateTimeKind.Utc).AddTicks(2106), "Zagreb", 10000 },
                    { 4, 1, new DateTime(2026, 4, 1, 13, 36, 44, 467, DateTimeKind.Utc).AddTicks(2107), "Banja Luka", 78000 },
                    { 5, 1, new DateTime(2026, 4, 1, 13, 36, 44, 467, DateTimeKind.Utc).AddTicks(2107), "Tuzla", 75000 },
                    { 6, 2, new DateTime(2026, 4, 1, 13, 36, 44, 467, DateTimeKind.Utc).AddTicks(2108), "Split", 21000 },
                    { 7, 3, new DateTime(2026, 4, 1, 13, 36, 44, 467, DateTimeKind.Utc).AddTicks(2109), "Beograd", 11000 },
                    { 8, 4, new DateTime(2026, 4, 1, 13, 36, 44, 467, DateTimeKind.Utc).AddTicks(2110), "Ljubljana", 1000 }
                });

            migrationBuilder.InsertData(
                table: "Users",
                columns: new[] { "Id", "BirthDate", "CityId", "CreatedAt", "Email", "FirstName", "Gender", "IsDeleted", "LastName", "PasswordHash", "PasswordSalt", "PhoneNumber", "ProfileImage", "RoleId", "Username" },
                values: new object[,]
                {
                    { 1, new DateTime(2001, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), 1, new DateTime(2026, 3, 1, 10, 0, 0, 0, DateTimeKind.Unspecified), "admin@eknjiga.com", "Admin", "Muško", false, "Admin", "9iEfXvv4hJuXR4bCipTAySrubo42fPAqOoSR4YWUlRw=", "boGlc7k/fmWmOtFKPzurrg==", "+38761123456", null, 1, "admin" },
                    { 2, new DateTime(2004, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), 2, new DateTime(2026, 3, 1, 10, 0, 0, 0, DateTimeKind.Unspecified), "maja.imamovic@eknjiga.com", "Maja", "Žensko", false, "Imamović", "siqkBrEg8pSFz3+fw+8jJGD5wUSqBmmwZEeuma3vut4=", "fltpobsWzAtZXyZshvXPtg==", "061987654", null, 2, "maja" },
                    { 3, new DateTime(2008, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), 1, new DateTime(2026, 3, 1, 10, 0, 0, 0, DateTimeKind.Unspecified), "haris@eknjiga.com", "Haris", "Muško", false, "Test", "siqkBrEg8pSFz3+fw+8jJGD5wUSqBmmwZEeuma3vut4=", "fltpobsWzAtZXyZshvXPtg==", "062333222", null, 2, "haris" },
                    { 4, new DateTime(1996, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), 3, new DateTime(2026, 3, 1, 10, 0, 0, 0, DateTimeKind.Unspecified), "user@knjiga.ba", "user", "Žensko", false, "user", "siqkBrEg8pSFz3+fw+8jJGD5wUSqBmmwZEeuma3vut4=", "fltpobsWzAtZXyZshvXPtg==", "+38598111222", null, 2, "user" },
                    { 5, new DateTime(1999, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), 4, new DateTime(2026, 3, 1, 10, 0, 0, 0, DateTimeKind.Unspecified), "erdin@eknjiga.com", "Erdin", "Muško", false, "K.", "siqkBrEg8pSFz3+fw+8jJGD5wUSqBmmwZEeuma3vut4=", "fltpobsWzAtZXyZshvXPtg==", "061111111", null, 3, "erdin" },
                    { 6, new DateTime(2002, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), 5, new DateTime(2026, 3, 1, 10, 0, 0, 0, DateTimeKind.Unspecified), "lejla@eknjiga.com", "Lejla", "Žensko", false, "S.", "siqkBrEg8pSFz3+fw+8jJGD5wUSqBmmwZEeuma3vut4=", "fltpobsWzAtZXyZshvXPtg==", "062222222", null, 2, "lejla" },
                    { 7, new DateTime(1997, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), 6, new DateTime(2026, 3, 1, 10, 0, 0, 0, DateTimeKind.Unspecified), "amar@eknjiga.com", "Amar", "Muško", false, "B.", "siqkBrEg8pSFz3+fw+8jJGD5wUSqBmmwZEeuma3vut4=", "fltpobsWzAtZXyZshvXPtg==", "063333333", null, 2, "amar" },
                    { 8, new DateTime(2000, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), 7, new DateTime(2026, 3, 1, 10, 0, 0, 0, DateTimeKind.Unspecified), "nina@eknjiga.rs", "Nina", "Žensko", false, "P.", "siqkBrEg8pSFz3+fw+8jJGD5wUSqBmmwZEeuma3vut4=", "fltpobsWzAtZXyZshvXPtg==", "+38160123456", null, 2, "nina" },
                    { 9, new DateTime(1995, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), 8, new DateTime(2026, 3, 1, 10, 0, 0, 0, DateTimeKind.Unspecified), "tine@eknjiga.si", "Tine", "Muško", false, "Z.", "siqkBrEg8pSFz3+fw+8jJGD5wUSqBmmwZEeuma3vut4=", "fltpobsWzAtZXyZshvXPtg==", "+38640111222", null, 2, "tine" },
                    { 10, new DateTime(1993, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), 6, new DateTime(2026, 3, 1, 10, 0, 0, 0, DateTimeKind.Unspecified), "ivica@eknjiga.ba", "Ivica", "Muško", false, "K.", "siqkBrEg8pSFz3+fw+8jJGD5wUSqBmmwZEeuma3vut4=", "fltpobsWzAtZXyZshvXPtg==", "+38598123456", null, 2, "ivica" }
                });

            migrationBuilder.InsertData(
                table: "Comments",
                columns: new[] { "Id", "Content", "CreatedAt", "UserId" },
                values: new object[,]
                {
                    { 1, "Odlična knjiga!", new DateTime(2026, 3, 1, 10, 0, 0, 0, DateTimeKind.Unspecified), 2 },
                    { 2, "Preporučujem svima!", new DateTime(2026, 3, 1, 10, 0, 0, 0, DateTimeKind.Unspecified), 1 },
                    { 3, "Zanimljiva knjiga o Mostaru.", new DateTime(2026, 3, 1, 10, 0, 0, 0, DateTimeKind.Unspecified), 3 },
                    { 4, "Oduševljena sam pričom u 'Zvjezdani Put'!", new DateTime(2026, 3, 1, 10, 0, 0, 0, DateTimeKind.Unspecified), 4 },
                    { 5, "Ljetne noći su me raznježile!", new DateTime(2026, 3, 1, 10, 0, 0, 0, DateTimeKind.Unspecified), 1 },
                    { 6, "Odlična nadogradnja C# znanja!", new DateTime(2026, 3, 1, 10, 0, 0, 0, DateTimeKind.Unspecified), 5 },
                    { 7, "Krimi je top, preporuka.", new DateTime(2026, 3, 1, 10, 0, 0, 0, DateTimeKind.Unspecified), 6 },
                    { 8, "Ekonomija – jasno i sažeto.", new DateTime(2026, 3, 1, 10, 0, 0, 0, DateTimeKind.Unspecified), 7 },
                    { 9, "Biografija mi se baš svidjela.", new DateTime(2026, 3, 1, 10, 0, 0, 0, DateTimeKind.Unspecified), 8 },
                    { 10, "ASP.NET primjerima je sve lakše.", new DateTime(2026, 3, 1, 10, 0, 0, 0, DateTimeKind.Unspecified), 9 },
                    { 11, "Mostarske priče su simpatične.", new DateTime(2026, 3, 1, 10, 0, 0, 0, DateTimeKind.Unspecified), 10 },
                    { 12, "Zločin na Neretvi je napet!", new DateTime(2026, 3, 1, 10, 0, 0, 0, DateTimeKind.Unspecified), 6 }
                });

            migrationBuilder.InsertData(
                table: "Orders",
                columns: new[] { "Id", "CreatedAt", "ExpiresAt", "OrderDate", "OrderStatus", "PaymentStatus", "PaypalCaptureId", "PaypalOrderId", "PaypalSandbox", "TotalPrice", "Type", "UserId" },
                values: new object[,]
                {
                    { 1, new DateTime(2026, 3, 25, 12, 0, 0, 0, DateTimeKind.Unspecified), null, new DateTime(2026, 3, 25, 12, 0, 0, 0, DateTimeKind.Unspecified), 2, 2, null, null, null, 14.99m, 0, 2 },
                    { 2, new DateTime(2026, 3, 29, 12, 0, 0, 0, DateTimeKind.Unspecified), new DateTime(2026, 4, 5, 12, 0, 0, 0, DateTimeKind.Unspecified), new DateTime(2026, 3, 29, 12, 0, 0, 0, DateTimeKind.Unspecified), 1, 1, null, null, null, 19.99m, 0, 3 },
                    { 3, new DateTime(2026, 3, 24, 12, 0, 0, 0, DateTimeKind.Unspecified), null, new DateTime(2026, 3, 24, 12, 0, 0, 0, DateTimeKind.Unspecified), 2, 2, null, null, null, 24.99m, 0, 4 },
                    { 4, new DateTime(2026, 3, 23, 12, 0, 0, 0, DateTimeKind.Unspecified), null, new DateTime(2026, 3, 23, 12, 0, 0, 0, DateTimeKind.Unspecified), 2, 2, null, null, null, 14.99m, 0, 1 },
                    { 5, new DateTime(2026, 3, 30, 10, 0, 0, 0, DateTimeKind.Unspecified), new DateTime(2026, 4, 6, 10, 0, 0, 0, DateTimeKind.Unspecified), new DateTime(2026, 3, 30, 10, 0, 0, 0, DateTimeKind.Unspecified), 1, 1, null, null, null, 52.48m, 0, 5 },
                    { 6, new DateTime(2026, 3, 20, 12, 0, 0, 0, DateTimeKind.Unspecified), null, new DateTime(2026, 3, 20, 12, 0, 0, 0, DateTimeKind.Unspecified), 2, 2, null, null, null, 21.50m, 0, 6 },
                    { 7, new DateTime(2026, 3, 18, 12, 0, 0, 0, DateTimeKind.Unspecified), null, new DateTime(2026, 3, 18, 12, 0, 0, 0, DateTimeKind.Unspecified), 2, 2, null, null, null, 36.00m, 0, 7 },
                    { 8, new DateTime(2026, 2, 20, 12, 0, 0, 0, DateTimeKind.Unspecified), new DateTime(2026, 2, 27, 12, 0, 0, 0, DateTimeKind.Unspecified), new DateTime(2026, 2, 20, 12, 0, 0, 0, DateTimeKind.Unspecified), 3, 0, null, null, null, 34.00m, 0, 8 },
                    { 9, new DateTime(2026, 3, 15, 12, 0, 0, 0, DateTimeKind.Unspecified), null, new DateTime(2026, 3, 15, 12, 0, 0, 0, DateTimeKind.Unspecified), 2, 2, null, null, null, 18.99m, 0, 9 },
                    { 10, new DateTime(2026, 3, 10, 12, 0, 0, 0, DateTimeKind.Unspecified), null, new DateTime(2026, 3, 10, 12, 0, 0, 0, DateTimeKind.Unspecified), 2, 2, null, null, null, 17.90m, 0, 10 },
                    { 11, new DateTime(2026, 2, 1, 12, 0, 0, 0, DateTimeKind.Unspecified), new DateTime(2026, 2, 3, 12, 0, 0, 0, DateTimeKind.Unspecified), new DateTime(2026, 2, 1, 12, 0, 0, 0, DateTimeKind.Unspecified), 3, 0, null, null, null, 19.99m, 1, 2 },
                    { 12, new DateTime(2026, 3, 30, 12, 0, 0, 0, DateTimeKind.Unspecified), new DateTime(2026, 4, 1, 12, 0, 0, 0, DateTimeKind.Unspecified), new DateTime(2026, 3, 30, 12, 0, 0, 0, DateTimeKind.Unspecified), 1, 1, null, null, null, 39.98m, 1, 3 },
                    { 13, new DateTime(2025, 12, 1, 12, 0, 0, 0, DateTimeKind.Unspecified), null, new DateTime(2025, 12, 1, 12, 0, 0, 0, DateTimeKind.Unspecified), 2, 2, null, null, null, 24.99m, 2, 4 },
                    { 14, new DateTime(2026, 1, 15, 12, 0, 0, 0, DateTimeKind.Unspecified), null, new DateTime(2026, 1, 15, 12, 0, 0, 0, DateTimeKind.Unspecified), 2, 2, null, null, null, 52.89m, 2, 5 }
                });

            migrationBuilder.InsertData(
                table: "Reviews",
                columns: new[] { "Id", "BookId", "CreatedAt", "Rating", "UserId" },
                values: new object[,]
                {
                    { 1, 2, new DateTime(2026, 2, 1, 10, 0, 0, 0, DateTimeKind.Unspecified), 5.0, 2 },
                    { 2, 4, new DateTime(2026, 2, 1, 10, 0, 0, 0, DateTimeKind.Unspecified), 4.0, 2 },
                    { 3, 2, new DateTime(2026, 2, 1, 10, 0, 0, 0, DateTimeKind.Unspecified), 5.0, 3 },
                    { 4, 4, new DateTime(2026, 2, 1, 10, 0, 0, 0, DateTimeKind.Unspecified), 4.0, 3 },
                    { 5, 6, new DateTime(2026, 2, 1, 10, 0, 0, 0, DateTimeKind.Unspecified), 5.0, 3 },
                    { 6, 11, new DateTime(2026, 2, 1, 10, 0, 0, 0, DateTimeKind.Unspecified), 4.0, 3 },
                    { 7, 2, new DateTime(2026, 2, 1, 10, 0, 0, 0, DateTimeKind.Unspecified), 5.0, 1 },
                    { 8, 4, new DateTime(2026, 2, 1, 10, 0, 0, 0, DateTimeKind.Unspecified), 4.0, 1 },
                    { 9, 11, new DateTime(2026, 2, 1, 10, 0, 0, 0, DateTimeKind.Unspecified), 5.0, 1 },
                    { 10, 6, new DateTime(2026, 2, 1, 10, 0, 0, 0, DateTimeKind.Unspecified), 4.0, 1 },
                    { 11, 2, new DateTime(2026, 2, 1, 10, 0, 0, 0, DateTimeKind.Unspecified), 4.0, 4 },
                    { 12, 4, new DateTime(2026, 2, 1, 10, 0, 0, 0, DateTimeKind.Unspecified), 5.0, 4 },
                    { 13, 6, new DateTime(2026, 2, 1, 10, 0, 0, 0, DateTimeKind.Unspecified), 5.0, 4 },
                    { 14, 11, new DateTime(2026, 2, 1, 10, 0, 0, 0, DateTimeKind.Unspecified), 5.0, 4 },
                    { 15, 5, new DateTime(2026, 2, 1, 10, 0, 0, 0, DateTimeKind.Unspecified), 5.0, 1 },
                    { 16, 5, new DateTime(2026, 2, 1, 10, 0, 0, 0, DateTimeKind.Unspecified), 5.0, 3 },
                    { 17, 5, new DateTime(2026, 2, 1, 10, 0, 0, 0, DateTimeKind.Unspecified), 4.0, 4 }
                });

            migrationBuilder.InsertData(
                table: "UserBooks",
                columns: new[] { "BookId", "UserId", "IsFavorite" },
                values: new object[,]
                {
                    { 2, 1, false },
                    { 2, 2, false },
                    { 5, 4, false },
                    { 8, 6, false },
                    { 11, 7, false },
                    { 10, 9, false },
                    { 9, 10, false }
                });

            migrationBuilder.InsertData(
                table: "UserReports",
                columns: new[] { "Id", "CreatedAt", "ProcessedAt", "ProcessedByUserId", "Reason", "ReportedByUserId", "Status", "UserReportedId" },
                values: new object[,]
                {
                    { 1, new DateTime(2026, 3, 1, 10, 0, 0, 0, DateTimeKind.Unspecified), null, null, "Neprimjeren komentar", 1, 0, 2 },
                    { 2, new DateTime(2026, 3, 1, 10, 0, 0, 0, DateTimeKind.Unspecified), null, null, "Spam ponašanje", 2, 1, 3 },
                    { 3, new DateTime(2026, 3, 1, 10, 0, 0, 0, DateTimeKind.Unspecified), null, null, "Uvredljiv sadržaj", 5, 0, 6 },
                    { 4, new DateTime(2026, 3, 1, 10, 0, 0, 0, DateTimeKind.Unspecified), new DateTime(2026, 3, 1, 11, 30, 0, 0, DateTimeKind.Unspecified), 1, "Spam linkovi", 6, 3, 7 },
                    { 5, new DateTime(2026, 3, 1, 10, 0, 0, 0, DateTimeKind.Unspecified), new DateTime(2026, 3, 1, 11, 50, 0, 0, DateTimeKind.Unspecified), 1, "Trolanje", 5, 2, 8 }
                });

            migrationBuilder.InsertData(
                table: "CommentAnswers",
                columns: new[] { "Id", "Content", "CreatedAt", "ParentCommentId", "UserId" },
                values: new object[,]
                {
                    { 1, "Slažem se, odlična knjiga!", new DateTime(2026, 3, 1, 10, 0, 0, 0, DateTimeKind.Unspecified), 1, 2 },
                    { 2, "Slažem se, preporučujem svima!", new DateTime(2026, 3, 1, 10, 0, 0, 0, DateTimeKind.Unspecified), 2, 1 },
                    { 3, "Drago mi je da ti se svidjela!", new DateTime(2026, 3, 1, 10, 0, 0, 0, DateTimeKind.Unspecified), 3, 1 },
                    { 4, "I meni je knjiga fantastična!", new DateTime(2026, 3, 1, 10, 0, 0, 0, DateTimeKind.Unspecified), 4, 2 },
                    { 5, "Baš tako, prelijepa priča!", new DateTime(2026, 3, 1, 10, 0, 0, 0, DateTimeKind.Unspecified), 5, 4 },
                    { 6, "Slažem se, odličan materijal.", new DateTime(2026, 3, 1, 10, 0, 0, 0, DateTimeKind.Unspecified), 6, 6 },
                    { 7, "I meni je krimi sjeo!", new DateTime(2026, 3, 1, 10, 0, 0, 0, DateTimeKind.Unspecified), 7, 7 },
                    { 8, "Super sažetak, hvala.", new DateTime(2026, 3, 1, 10, 0, 0, 0, DateTimeKind.Unspecified), 8, 8 },
                    { 9, "Baš inspirativno.", new DateTime(2026, 3, 1, 10, 0, 0, 0, DateTimeKind.Unspecified), 9, 9 },
                    { 10, "Odlični primjeri u knjizi.", new DateTime(2026, 3, 1, 10, 0, 0, 0, DateTimeKind.Unspecified), 10, 10 },
                    { 11, "Top priče!", new DateTime(2026, 3, 1, 10, 0, 0, 0, DateTimeKind.Unspecified), 11, 5 },
                    { 12, "Drži pažnju do kraja.", new DateTime(2026, 3, 1, 10, 0, 0, 0, DateTimeKind.Unspecified), 12, 7 }
                });

            migrationBuilder.InsertData(
                table: "CommentReactions",
                columns: new[] { "Id", "CommentAnswerId", "CommentId", "IsLike", "UserId" },
                values: new object[,]
                {
                    { 1, null, 1, true, 1 },
                    { 2, null, 1, true, 3 },
                    { 3, null, 1, true, 4 },
                    { 4, null, 2, true, 2 },
                    { 5, null, 2, false, 3 },
                    { 6, null, 2, false, 4 },
                    { 7, null, 2, true, 1 },
                    { 10, null, 3, false, 1 },
                    { 11, null, 3, false, 2 },
                    { 12, null, 4, true, 1 },
                    { 13, null, 4, true, 2 },
                    { 14, null, 4, false, 3 },
                    { 15, null, 4, true, 4 },
                    { 16, null, 5, true, 1 },
                    { 17, null, 5, false, 2 },
                    { 18, null, 5, true, 3 },
                    { 19, null, 5, true, 4 },
                    { 24, null, 6, true, 6 },
                    { 25, null, 6, true, 7 },
                    { 26, null, 7, true, 8 },
                    { 27, null, 8, true, 9 },
                    { 28, null, 9, true, 10 },
                    { 29, null, 10, true, 5 },
                    { 30, null, 11, false, 6 },
                    { 31, null, 12, true, 7 },
                    { 39, null, 8, true, 5 }
                });

            migrationBuilder.InsertData(
                table: "OrderItems",
                columns: new[] { "Id", "BookId", "IsPdfPurchase", "OrderId", "Quantity", "UnitPrice" },
                values: new object[,]
                {
                    { 1, 2, true, 1, 1, 14.99m },
                    { 2, 4, false, 2, 1, 19.99m },
                    { 3, 5, true, 3, 1, 24.99m },
                    { 4, 2, true, 4, 1, 14.99m },
                    { 5, 6, false, 5, 1, 39.99m },
                    { 6, 8, true, 6, 1, 21.50m },
                    { 7, 11, true, 7, 1, 36.00m },
                    { 8, 12, false, 8, 1, 22.00m },
                    { 9, 10, true, 9, 1, 18.99m },
                    { 10, 9, true, 10, 1, 17.90m },
                    { 11, 7, false, 5, 1, 12.49m },
                    { 12, 7, false, 8, 1, 12.49m },
                    { 13, 4, false, 11, 1, 19.99m },
                    { 14, 2, false, 12, 1, 14.99m },
                    { 15, 5, false, 12, 1, 24.99m },
                    { 16, 5, true, 13, 1, 24.99m },
                    { 17, 1, true, 14, 1, 29.99m },
                    { 18, 7, false, 14, 1, 12.49m },
                    { 19, 2, false, 14, 1, 10.41m }
                });

            migrationBuilder.InsertData(
                table: "CommentReactions",
                columns: new[] { "Id", "CommentAnswerId", "CommentId", "IsLike", "UserId" },
                values: new object[,]
                {
                    { 20, 1, null, true, 1 },
                    { 21, 1, null, true, 3 },
                    { 22, 2, null, false, 2 },
                    { 23, 2, null, true, 4 },
                    { 32, 6, null, true, 8 },
                    { 33, 7, null, true, 9 },
                    { 34, 8, null, true, 10 },
                    { 35, 9, null, true, 5 },
                    { 36, 10, null, true, 6 },
                    { 37, 11, null, false, 7 },
                    { 38, 12, null, true, 8 },
                    { 40, 7, null, true, 10 }
                });

            migrationBuilder.CreateIndex(
                name: "IX_BookAuthors_AuthorId",
                table: "BookAuthors",
                column: "AuthorId");

            migrationBuilder.CreateIndex(
                name: "IX_BookCategories_CategoryId",
                table: "BookCategories",
                column: "CategoryId");

            migrationBuilder.CreateIndex(
                name: "IX_Cities_CountryId",
                table: "Cities",
                column: "CountryId");

            migrationBuilder.CreateIndex(
                name: "IX_CommentAnswers_ParentCommentId",
                table: "CommentAnswers",
                column: "ParentCommentId");

            migrationBuilder.CreateIndex(
                name: "IX_CommentAnswers_UserId",
                table: "CommentAnswers",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_CommentReactions_CommentAnswerId_UserId",
                table: "CommentReactions",
                columns: new[] { "CommentAnswerId", "UserId" },
                unique: true,
                filter: "[CommentAnswerId] IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "IX_CommentReactions_CommentId_UserId",
                table: "CommentReactions",
                columns: new[] { "CommentId", "UserId" },
                unique: true,
                filter: "[CommentId] IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "IX_CommentReactions_UserId",
                table: "CommentReactions",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_Comments_UserId",
                table: "Comments",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_OrderItems_BookId",
                table: "OrderItems",
                column: "BookId");

            migrationBuilder.CreateIndex(
                name: "IX_OrderItems_OrderId",
                table: "OrderItems",
                column: "OrderId");

            migrationBuilder.CreateIndex(
                name: "IX_Orders_UserId",
                table: "Orders",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_Reviews_BookId",
                table: "Reviews",
                column: "BookId");

            migrationBuilder.CreateIndex(
                name: "IX_Reviews_UserId",
                table: "Reviews",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_UserBooks_BookId",
                table: "UserBooks",
                column: "BookId");

            migrationBuilder.CreateIndex(
                name: "IX_UserReports_ProcessedByUserId",
                table: "UserReports",
                column: "ProcessedByUserId");

            migrationBuilder.CreateIndex(
                name: "IX_UserReports_ReportedByUserId",
                table: "UserReports",
                column: "ReportedByUserId");

            migrationBuilder.CreateIndex(
                name: "IX_UserReports_UserReportedId",
                table: "UserReports",
                column: "UserReportedId");

            migrationBuilder.CreateIndex(
                name: "IX_Users_CityId",
                table: "Users",
                column: "CityId");

            migrationBuilder.CreateIndex(
                name: "IX_Users_Email",
                table: "Users",
                column: "Email",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Users_RoleId",
                table: "Users",
                column: "RoleId");

            migrationBuilder.CreateIndex(
                name: "IX_Users_Username",
                table: "Users",
                column: "Username",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "BookAuthors");

            migrationBuilder.DropTable(
                name: "BookCategories");

            migrationBuilder.DropTable(
                name: "CommentReactions");

            migrationBuilder.DropTable(
                name: "OrderItems");

            migrationBuilder.DropTable(
                name: "PaypalLogs");

            migrationBuilder.DropTable(
                name: "Reviews");

            migrationBuilder.DropTable(
                name: "UserBooks");

            migrationBuilder.DropTable(
                name: "UserReports");

            migrationBuilder.DropTable(
                name: "Authors");

            migrationBuilder.DropTable(
                name: "Categories");

            migrationBuilder.DropTable(
                name: "CommentAnswers");

            migrationBuilder.DropTable(
                name: "Orders");

            migrationBuilder.DropTable(
                name: "Books");

            migrationBuilder.DropTable(
                name: "Comments");

            migrationBuilder.DropTable(
                name: "Users");

            migrationBuilder.DropTable(
                name: "Cities");

            migrationBuilder.DropTable(
                name: "Roles");

            migrationBuilder.DropTable(
                name: "Countries");
        }
    }
}
