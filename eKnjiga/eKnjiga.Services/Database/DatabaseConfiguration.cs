using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;

namespace eKnjiga.Services.Database
{
    public static class DatabaseConfiguration
    {
        public static void AddDatabaseServices(this IServiceCollection services, string connectionString)
        {
            services.AddDbContext<eKnjigaDbContext>(options =>
                options.UseSqlServer(connectionString));
        }

        public static void AddDatabaseEComm(this IServiceCollection services, string connectionString)
        {
            services.AddDbContext<eKnjigaDbContext>(options =>
                options.UseSqlServer(connectionString));
        }
    }
} 