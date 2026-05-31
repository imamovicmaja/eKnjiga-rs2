using eKnjiga.Services.Database;
using eKnjiga.Worker;
using eKnjiga.Worker.Messaging;
using Microsoft.EntityFrameworkCore;

var builder = Host.CreateApplicationBuilder(args);

builder.Services.AddDbContext<eKnjigaDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

builder.Services.AddHostedService<RabbitEmailConsumer>();
builder.Services.AddHostedService<ExpiredOrdersWorker>();

var host = builder.Build();
await host.RunAsync();