using eKnjiga.Services;
using eKnjiga.Services.Database;
using eKnjiga.Services.Database.seedAssets;
using eKnjiga.WebAPI.Filters;
using eKnjiga.WebAPI.Middleware;
using Mapster;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Authentication;
using Microsoft.Extensions.FileProviders;
using Microsoft.Extensions.Configuration;
using Microsoft.OpenApi.Models;
using eKnjiga.Services.Messaging;
using System.Net;
using System;
using eKnjiga.Services;

var builder = WebApplication.CreateBuilder(args);

builder.WebHost.UseUrls("http://0.0.0.0:80");

// Add services to the container.
builder.Services.AddTransient<IUserService, UserService>();
builder.Services.AddTransient<IRoleService, RoleService>();
builder.Services.AddTransient<IAuthorService, AuthorService>();
builder.Services.AddScoped<IBookService, BookService>();
builder.Services.AddTransient<ICategoryService, CategoryService>();
builder.Services.AddTransient<ICityService, CityService>();
builder.Services.AddTransient<ICommentService, CommentService>();
builder.Services.AddTransient<ICommentAnswerService, CommentAnswerService>();
builder.Services.AddTransient<ICountryService, CountryService>();
builder.Services.AddTransient<IOrderService, OrderService>();
builder.Services.AddTransient<IReviewService, ReviewService>();
builder.Services.AddTransient<IUserReportService, UserReportService>();
builder.Services.AddTransient<ICommentReactionService, CommentReactionService>();
builder.Services.AddScoped<IRecommendationService, RecommendationService>();

builder.Services.AddTransient<IPaypalService, PaypalService>();
builder.Services.AddHttpClient("paypal", client =>
{
    client.Timeout = TimeSpan.FromSeconds(300);
    client.DefaultRequestHeaders.Accept.Add(
        new System.Net.Http.Headers.MediaTypeWithQualityHeaderValue("application/json"));
})
.ConfigurePrimaryHttpMessageHandler(() => new SocketsHttpHandler
{
    AutomaticDecompression = DecompressionMethods.GZip | DecompressionMethods.Deflate,
    PooledConnectionLifetime = TimeSpan.FromMinutes(30),
    ConnectTimeout = TimeSpan.FromSeconds(60),
});

builder.Services.AddHttpContextAccessor();

builder.Services.AddMapster();

// Configure database
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection")
    ?? throw new InvalidOperationException("Connection string 'DefaultConnection' nije postavljen.");

builder.Services.AddDatabaseServices(connectionString);

builder.Services.AddAuthentication("BasicAuthentication")
    .AddScheme<AuthenticationSchemeOptions, BasicAuthenticationHandler>("BasicAuthentication", null);

builder.Services.AddAuthorization();

builder.Services.AddSingleton<IEmailQueue, RabbitEmailQueue>();

builder.Services.AddControllers();

// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.AddSecurityDefinition("BasicAuthentication", new OpenApiSecurityScheme
    {
        Name = "Authorization",
        Type = SecuritySchemeType.Http,
        Scheme = "basic",
        In = ParameterLocation.Header,
        Description = "Basic Authorization header using the Basic scheme."
    });

    c.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "BasicAuthentication"
                }
            },
            new string[] { }
        }
    });
});

builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

var app = builder.Build();


// Kreiranje baze + runtime seed za covere i PDF-ove
using (var scope = app.Services.CreateScope())
{
    var dbContext = scope.ServiceProvider.GetRequiredService<eKnjigaDbContext>();

    dbContext.Database.Migrate();

    DbSeeder.SeedBookFiles(dbContext);
    // DbSeeder.SeedOrders(dbContext);
}

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

// app.UseHttpsRedirection();

app.UseMiddleware<ExceptionHandlingMiddleware>();

var webRootPath = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot");

if (!Directory.Exists(webRootPath))
{
    Directory.CreateDirectory(webRootPath);
}

// CORS mora ići prije static files da bi slike radile i u Chrome-u
app.UseCors("AllowAll");

app.UseStaticFiles(new StaticFileOptions
{
    FileProvider = new PhysicalFileProvider(webRootPath),
    RequestPath = "",
    OnPrepareResponse = ctx =>
    {
        var headers = ctx.Context.Response.Headers;

        headers["Cache-Control"] = "no-cache";
        headers["Access-Control-Allow-Origin"] = "*";

        var ext = Path.GetExtension(ctx.File.Name).ToLowerInvariant();
        if (ext == ".png")
            ctx.Context.Response.ContentType = "image/png";
        else if (ext == ".jpg" || ext == ".jpeg")
            ctx.Context.Response.ContentType = "image/jpeg";
        else if (ext == ".webp")
            ctx.Context.Response.ContentType = "image/webp";
    }
});

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

app.Run();