using eKnjiga.Services;
using eKnjiga.Services.Database;
using eKnjiga.WebAPI.Filters;
using Mapster;
using MapsterMapper;
using Microsoft.AspNetCore.Authentication;
using Microsoft.OpenApi.Models;
using eKnjiga.Services.Messaging;

var builder = WebApplication.CreateBuilder(args);

builder.WebHost.UseUrls("http://0.0.0.0:80");

// Add services to the container.
builder.Services.AddTransient<IUserService, UserService>();
builder.Services.AddTransient<IRoleService, RoleService>();
builder.Services.AddTransient<IAuthorService, AuthorService>();
builder.Services.AddTransient<IAuthorService, AuthorService>();
builder.Services.AddTransient<IBookService, BookService>();
builder.Services.AddTransient<ICategoryService, CategoryService>();
builder.Services.AddTransient<ICityService, CityService>();
builder.Services.AddTransient<ICommentService, CommentService>();
builder.Services.AddTransient<ICommentAnswerService, CommentAnswerService>();
builder.Services.AddTransient<ICountryService, CountryService>();
builder.Services.AddTransient<IOrderService, OrderService>();
builder.Services.AddTransient<IReviewService, ReviewService>();
builder.Services.AddTransient<IUserReportService, UserReportService>();
builder.Services.AddTransient<ICommentReactionService, CommentReactionService>();
builder.Services.AddTransient<IRecommendationService, RecommendationService>();

builder.Services.AddTransient<IPaypalService, PaypalService>();
builder.Services.AddHttpClient("paypal");

builder.Services.AddMapster();
// Configure database
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection") ?? "Server=localhost;Database=eKnjigaDb;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True";
builder.Services.AddDatabaseServices(connectionString);
builder.Services.AddAuthentication("BasicAuthentication")
    .AddScheme<AuthenticationSchemeOptions, BasicAuthenticationHandler>("BasicAuthentication", null);


builder.Services.AddSingleton<IEmailQueue>(_ =>
    new RabbitEmailQueue(builder.Configuration["Rabbit:ConnectionString"]!));
builder.Services.AddHostedService<EmailWorker>();

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
        Description = "Basic Authorization header using the Bearer scheme."
    });
    c.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme { Reference = new OpenApiReference { Type = ReferenceType.SecurityScheme, Id = "BasicAuthentication" } },
            new string[] { }
        }
    });
});

builder.Services.AddCors(options => {
    options.AddPolicy("AllowAll", policy => {
        policy.AllowAnyOrigin().AllowAnyMethod().AllowAnyHeader();
    });
});


var app = builder.Build();

// Ensure database is created
using (var scope = app.Services.CreateScope())
{
    var dbContext = scope.ServiceProvider.GetRequiredService<eKnjigaDbContext>();
    dbContext.Database.EnsureCreated();
}

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

app.UseAuthentication();
app.UseAuthorization(); 

app.UseCors("AllowAll");

app.MapControllers();

app.Run();
