using eKnjiga.Services;
using eKnjiga.Services.Database;
using eKnjiga.Services.Database.seedAssets;
using eKnjiga.WebAPI.Middleware;
using Mapster;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.FileProviders;
using Microsoft.OpenApi.Models;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using System.Text;
using eKnjiga.Services.Messaging;
using System.Net;
using DotNetEnv;


Env.Load("../.env");

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
builder.Services.AddScoped<INotificationService, NotificationService>();
builder.Services.AddScoped<IJwtService, JwtService>();

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

//builder.Services.AddAuthentication("BasicAuthentication")
//.AddScheme<AuthenticationSchemeOptions, BasicAuthenticationHandler>("BasicAuthentication", null);

var jwtKey = builder.Configuration["Jwt:Key"]
    ?? throw new InvalidOperationException("JWT ključ nije konfigurisan.");

var jwtIssuer = builder.Configuration["Jwt:Issuer"] ?? "eKnjiga";
var jwtAudience = builder.Configuration["Jwt:Audience"] ?? "eKnjigaUsers";

builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.RequireHttpsMetadata = false;
        options.SaveToken = true;

        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey)),

            ValidateIssuer = true,
            ValidIssuer = jwtIssuer,

            ValidateAudience = true,
            ValidAudience = jwtAudience,

            ValidateLifetime = true,
            ClockSkew = TimeSpan.Zero
        };

        options.Events = new JwtBearerEvents
        {
            OnTokenValidated = async context =>
            {
                var authHeader = context.Request.Headers["Authorization"].ToString();

                if (string.IsNullOrWhiteSpace(authHeader) ||
                    !authHeader.StartsWith("Bearer "))
                    return;

                var token = authHeader["Bearer ".Length..].Trim();

                var db = context.HttpContext.RequestServices
                    .GetRequiredService<eKnjigaDbContext>();

                var isRevoked = await db.RevokedTokens
                    .AnyAsync(x => x.Token == token);

                if (isRevoked)
                    context.Fail("Token je odjavljen.");
            }
        };
    });

builder.Services.AddAuthorization();

builder.Services.AddSingleton<IEmailQueue, RabbitEmailQueue>();

builder.Services.AddControllers();

// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Description = "Unesi JWT token u formatu: Bearer {token}",
        Name = "Authorization",
        In = ParameterLocation.Header,
        Type = SecuritySchemeType.ApiKey,
        Scheme = "Bearer"
    });

    c.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            Array.Empty<string>()
        }
    });
});

builder.Services.AddCors(options =>
{
    options.AddPolicy("FrontendPolicy", policy =>
    {
        policy
            .WithOrigins(
                "http://localhost",
                "https://localhost"
            )
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

app.UseCors("FrontendPolicy");

app.UseStaticFiles(new StaticFileOptions
{
    FileProvider = new PhysicalFileProvider(webRootPath),
    RequestPath = "",
    OnPrepareResponse = ctx =>
    {
        var headers = ctx.Context.Response.Headers;

        headers["Cache-Control"] = "no-cache";

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