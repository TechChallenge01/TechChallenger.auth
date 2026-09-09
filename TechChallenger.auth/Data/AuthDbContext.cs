using Microsoft.EntityFrameworkCore;

namespace TechChallenger.auth.Data
{
    public class AuthDbContext : DbContext
    {
        public AuthDbContext(DbContextOptions<AuthDbContext> options) : base(options) { }

        public DbSet<ClienteReadModel> Clientes { get; set; } = null!;

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<ClienteReadModel>(builder =>
            {
                builder.ToTable("Clientes");
                builder.HasKey(c => c.Id);
                builder.Property(c => c.Nome).HasMaxLength(100);
                builder.Property(c => c.Cpf).HasMaxLength(11);
                builder.Property(c => c.Email).HasMaxLength(200);
            });

            base.OnModelCreating(modelBuilder);
        }
    }
}
