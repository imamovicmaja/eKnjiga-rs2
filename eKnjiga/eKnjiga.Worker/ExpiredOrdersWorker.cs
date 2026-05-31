using eKnjiga.Model.Enums;
using eKnjiga.Services.Database;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace eKnjiga.Worker
{
    public class ExpiredOrdersWorker : BackgroundService
    {
        private readonly IServiceScopeFactory _scopeFactory;
        private readonly ILogger<ExpiredOrdersWorker> _logger;

        public ExpiredOrdersWorker(
            IServiceScopeFactory scopeFactory,
            ILogger<ExpiredOrdersWorker> logger)
        {
            _scopeFactory = scopeFactory;
            _logger = logger;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("ExpiredOrdersWorker started.");

            while (!stoppingToken.IsCancellationRequested)
            {
                try
                {
                    using var scope = _scopeFactory.CreateScope();
                    var context = scope.ServiceProvider.GetRequiredService<eKnjigaDbContext>();

                    var now = DateTime.UtcNow;

                    var expiredOrders = await context.Orders
                        .Where(o =>
                            o.ExpiresAt.HasValue &&
                            o.ExpiresAt.Value <= now &&
                            (o.OrderStatus == OrderStatus.Pending || o.OrderStatus == OrderStatus.Processing) &&
                            (
                                o.Type == OrderType.Reservation ||
                                (o.Type == OrderType.Purchase && o.PaymentStatus != PaymentStatus.Paid)
                            ))
                        .ToListAsync(stoppingToken);

                    if (expiredOrders.Any())
                    {
                        foreach (var order in expiredOrders)
                        {
                            order.OrderStatus = OrderStatus.Cancelled;
                        }

                        await context.SaveChangesAsync(stoppingToken);

                        _logger.LogInformation(
                            "Automatically cancelled {Count} expired orders/reservations.",
                            expiredOrders.Count);
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error while processing expired orders.");
                }

                await Task.Delay(TimeSpan.FromMinutes(5), stoppingToken);
            }

            _logger.LogInformation("ExpiredOrdersWorker stopped.");
        }
    }
}