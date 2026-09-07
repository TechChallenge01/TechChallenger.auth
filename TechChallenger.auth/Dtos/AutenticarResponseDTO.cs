namespace TechChallenger.auth.Dtos
{
    public record AutenticarResponseDTO
    {
        public string Token { get; init; } = string.Empty;
        public DateTime Expiracao { get; init; }
        public Guid ClienteId { get; init; }
        public string Nome { get; init; } = string.Empty;
    }
}
