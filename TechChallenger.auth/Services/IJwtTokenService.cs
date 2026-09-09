using TechChallenger.auth.Data;

namespace TechChallenger.auth.Services
{
    public interface IJwtTokenService
    {
        (string token, DateTime expiracao) GerarToken(ClienteReadModel cliente);
    }
}
