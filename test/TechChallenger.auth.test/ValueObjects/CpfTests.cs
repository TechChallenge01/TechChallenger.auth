using FluentAssertions;
using TechChallenger.auth.ValueObjects;

namespace TechChallenger.auth.test.ValueObjects
{
    public class CpfTests
    {
        [Theory]
        [InlineData("52998224725")]
        [InlineData("529.982.247-25")]
        [InlineData("111.444.777-35")]
        public void Deve_Aceitar_Cpf_Valido_Com_Ou_Sem_Formatacao(string cpfInformado)
        {
            var cpf = new Cpf(cpfInformado);

            cpf.Valor.Should().Be(cpfInformado.Replace(".", "").Replace("-", "").Replace("/", ""));
        }

        [Fact]
        public void Deve_Rejeitar_Cpf_Nulo()
        {
            var act = () => new Cpf(null!);

            act.Should().Throw<ArgumentException>();
        }

        [Theory]
        [InlineData("")]
        [InlineData("123")]
        [InlineData("123456789012")]
        public void Deve_Rejeitar_Cpf_Com_Tamanho_Invalido(string cpfInvalido)
        {
            var act = () => new Cpf(cpfInvalido);

            act.Should().Throw<ArgumentException>();
        }

        [Theory]
        [InlineData("00000000000")]
        [InlineData("11111111111")]
        [InlineData("99999999999")]
        public void Deve_Rejeitar_Cpf_Com_Digitos_Repetidos(string cpfInvalido)
        {
            var act = () => new Cpf(cpfInvalido);

            act.Should().Throw<ArgumentException>();
        }

        [Theory]
        [InlineData("52998224700")]
        [InlineData("12345678900")]
        public void Deve_Rejeitar_Cpf_Com_Digito_Verificador_Invalido(string cpfInvalido)
        {
            var act = () => new Cpf(cpfInvalido);

            act.Should().Throw<ArgumentException>();
        }
    }
}
