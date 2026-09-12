using System.IdentityModel.Tokens.Jwt;
using FluentAssertions;
using Microsoft.Extensions.Configuration;
using TechChallenger.auth.Data;
using TechChallenger.auth.Services;

namespace TechChallenger.auth.test.Services
{
    public class JwtTokenServiceTests
    {
        private static IConfiguration BuildConfig() =>
            new ConfigurationBuilder()
                .AddInMemoryCollection(new Dictionary<string, string?>
                {
                    ["Jwt:Key"] = "f3a7c9b8e1d2a3f4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8",
                    ["Jwt:Issuer"] = "TechChallenger",
                    ["Jwt:Audience"] = "TechChallenger",
                    ["Jwt:ExpiracaoHoras"] = "8"
                })
                .Build();

        private static ClienteReadModel BuildCliente() => new()
        {
            Id = Guid.NewGuid(),
            Nome = "Maria Teste",
            Cpf = "52998224725",
            Email = "maria@teste.com",
            Ativo = true
        };

        [Fact]
        public void Deve_Gerar_Token_Assinado_Com_Claims_Do_Cliente()
        {
            var service = new JwtTokenService(BuildConfig());
            var cliente = BuildCliente();

            var (token, expiracao) = service.GerarToken(cliente);

            token.Should().NotBeNullOrWhiteSpace();

            var jwt = new JwtSecurityTokenHandler().ReadJwtToken(token);
            jwt.Issuer.Should().Be("TechChallenger");
            jwt.Audiences.Should().Contain("TechChallenger");
            jwt.Claims.First(c => c.Type == JwtRegisteredClaimNames.Sub).Value.Should().Be(cliente.Id.ToString());
            jwt.Claims.First(c => c.Type == JwtRegisteredClaimNames.Email).Value.Should().Be(cliente.Email);
            jwt.Claims.First(c => c.Type == System.Security.Claims.ClaimTypes.Name).Value.Should().Be(cliente.Nome);
            jwt.Claims.First(c => c.Type == System.Security.Claims.ClaimTypes.Role).Value.Should().Be("Cliente");
            jwt.Claims.First(c => c.Type == "cpf").Value.Should().Be(cliente.Cpf);
            expiracao.Should().BeCloseTo(DateTime.UtcNow.AddHours(8), TimeSpan.FromMinutes(1));
        }

        [Fact]
        public void Deve_Gerar_Tokens_Diferentes_Para_Chamadas_Distintas()
        {
            var service = new JwtTokenService(BuildConfig());
            var cliente = BuildCliente();

            var (token1, _) = service.GerarToken(cliente);
            var (token2, _) = service.GerarToken(cliente);

            token1.Should().NotBe(token2);
        }
    }
}
