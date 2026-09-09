namespace TechChallenger.auth.Data
{
    public class ClienteReadModel
    {
        public Guid Id { get; set; }
        public string Nome { get; set; } = string.Empty;
        public string? Cpf { get; set; }
        public string Email { get; set; } = string.Empty;
        public bool Ativo { get; set; }
    }
}
