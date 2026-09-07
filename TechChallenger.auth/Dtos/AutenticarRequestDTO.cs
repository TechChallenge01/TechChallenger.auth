namespace TechChallenger.auth.Dtos
{
    public record AutenticarRequestDTO
    {
        public string Cpf { get; init; } = string.Empty;
    }
}
