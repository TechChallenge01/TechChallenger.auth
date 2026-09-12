using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;
using TechChallenger.auth.Data;

namespace TechChallenger.auth.test.Fixtures
{
    // Troca o AuthDbContext (SQL Server) por um provider InMemory isolado por
    // instancia de fabrica, para que os testes de endpoint nao dependam de banco real.
    public class AuthApiFactory : WebApplicationFactory<Program>
    {
        private readonly string _databaseName = Guid.NewGuid().ToString();

        protected override void ConfigureWebHost(IWebHostBuilder builder)
        {
            builder.ConfigureServices(services =>
            {
                services.RemoveAll<DbContextOptions<AuthDbContext>>();

                services.AddDbContext<AuthDbContext>(options =>
                    options.UseInMemoryDatabase(_databaseName));
            });
        }

        public void SeedCliente(ClienteReadModel cliente)
        {
            using var scope = Services.CreateScope();
            var db = scope.ServiceProvider.GetRequiredService<AuthDbContext>();
            db.Clientes.Add(cliente);
            db.SaveChanges();
        }
    }
}
