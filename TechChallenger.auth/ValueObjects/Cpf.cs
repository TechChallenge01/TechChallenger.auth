namespace TechChallenger.auth.ValueObjects
{
    public class Cpf
    {
        public Cpf(string cpf)
        {
            if (cpf is null)
                throw new ArgumentException("Cpf não pode ser nullo");

            cpf = cpf.Replace(".", "").Replace("-", "").Replace("/", "");
            ValidarCpf(cpf);

            Valor = cpf;
        }

        public string Valor { get; private set; }

        private void ValidarCpf(string cpf)
        {
            if (string.IsNullOrEmpty(cpf))
                throw new ArgumentException("O CPF não pode ser vazio.", nameof(cpf));

            if (cpf.Length != 11)
                throw new ArgumentException("CPF deve conter 11 dígitos.", nameof(cpf));

            if (cpf.Distinct().Count() == 1)
                throw new ArgumentException("CPF inválido.", nameof(cpf));

            int[] multiplicador1 = { 10, 9, 8, 7, 6, 5, 4, 3, 2 };
            int[] multiplicador2 = { 11, 10, 9, 8, 7, 6, 5, 4, 3, 2 };

            string tempCpf = cpf.Substring(0, 9);
            int soma = 0;

            for (int i = 0; i < 9; i++)
                soma += (tempCpf[i] - '0') * multiplicador1[i];

            int resto = soma % 11;
            resto = resto < 2 ? 0 : 11 - resto;

            string digito = resto.ToString();
            tempCpf += digito;

            soma = 0;

            for (int i = 0; i < 10; i++)
                soma += (tempCpf[i] - '0') * multiplicador2[i];

            resto = soma % 11;
            resto = resto < 2 ? 0 : 11 - resto;

            digito += resto.ToString();

            if (!cpf.EndsWith(digito))
                throw new ArgumentException("CPF inválido.", nameof(cpf));
        }
    }
}
