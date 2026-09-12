using System.Net;
using System.Net.Http.Json;
using FluentAssertions;
using TechChallenger.auth.Data;
using TechChallenger.auth.Dtos;
using TechChallenger.auth.test.Fixtures;

namespace TechChallenger.auth.test.EndPoints
{
    public class AuthenticateTests : IClassFixture<AuthApiFactory>
    {
        private readonly AuthApiFactory _factory;

        public AuthenticateTests(AuthApiFactory factory)
        {
            _factory = factory;
        }

        [Fact]
        public async Task Deve_Retornar_200_E_Token_Quando_Cliente_Existe_E_Esta_Ativo()
        {
            var cpf = "52998224725";
            _factory.SeedCliente(new ClienteReadModel
            {
                Id = Guid.NewGuid(),
                Nome = "Cliente Ativo",
                Cpf = cpf,
                Email = "ativo@teste.com",
                Ativo = true
            });
            var client = _factory.CreateClient();

            var response = await client.PostAsJsonAsync("/auth/cpf", new AutenticarRequestDTO { Cpf = cpf });

            response.StatusCode.Should().Be(HttpStatusCode.OK);
            var body = await response.Content.ReadFromJsonAsync<AutenticarResponseDTO>();
            body.Should().NotBeNull();
            body!.Token.Should().NotBeNullOrWhiteSpace();
            body.Nome.Should().Be("Cliente Ativo");
        }

        [Fact]
        public async Task Deve_Retornar_403_Quando_Cliente_Existe_Mas_Esta_Inativo()
        {
            var cpf = "11144477735";
            _factory.SeedCliente(new ClienteReadModel
            {
                Id = Guid.NewGuid(),
                Nome = "Cliente Inativo",
                Cpf = cpf,
                Email = "inativo@teste.com",
                Ativo = false
            });
            var client = _factory.CreateClient();

            var response = await client.PostAsJsonAsync("/auth/cpf", new AutenticarRequestDTO { Cpf = cpf });

            response.StatusCode.Should().Be(HttpStatusCode.Forbidden);
        }

        [Fact]
        public async Task Deve_Retornar_404_Quando_Cliente_Nao_Existe()
        {
            var client = _factory.CreateClient();

            var response = await client.PostAsJsonAsync("/auth/cpf", new AutenticarRequestDTO { Cpf = "12345678909" });

            response.StatusCode.Should().Be(HttpStatusCode.NotFound);
        }

        [Fact]
        public async Task Deve_Retornar_400_Quando_Cpf_Tem_Formato_Invalido()
        {
            var client = _factory.CreateClient();

            var response = await client.PostAsJsonAsync("/auth/cpf", new AutenticarRequestDTO { Cpf = "123" });

            response.StatusCode.Should().Be(HttpStatusCode.BadRequest);
        }
    }
}
