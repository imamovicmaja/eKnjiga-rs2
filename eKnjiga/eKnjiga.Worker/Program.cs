using eKnjiga.Worker.Messaging;

var builder = Host.CreateApplicationBuilder(args);

builder.Services.AddHostedService<RabbitEmailConsumer>();

var host = builder.Build();
await host.RunAsync();
