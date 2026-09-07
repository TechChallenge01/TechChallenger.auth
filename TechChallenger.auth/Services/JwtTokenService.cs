using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.IdentityModel.Tokens;
using TechChallenger.auth.Data;

namespace TechChallenger.auth.Services
{
    public class JwtTokenService : IJwtTokenService
    {
        private readonly IConfiguration _config;

        public JwtTokenService(IConfiguration configuration)
        {
            _config = configuration;
        }

        // Emite o mesmo formato de claims (sub/email/name/role/jti) usado pelo
        // JwtService da TechChallenge API, assinado com a mesma chave/issuer/audience
        // (Jwt:Key, Jwt:Issuer, Jwt:Audience) — os tokens são intercambiáveis entre os dois serviços.
        public (string token, DateTime expiracao) GerarToken(ClienteReadModel cliente)
        {
            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_config["Jwt:Key"]!));
            var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);
            var expiracao = DateTime.UtcNow.AddHours(double.Parse(_config["Jwt:ExpiracaoHoras"]!));

            var claims = new[]
            {
                new Claim(JwtRegisteredClaimNames.Sub,   cliente.Id.ToString()),
                new Claim(JwtRegisteredClaimNames.Email, cliente.Email ?? string.Empty),
                new Claim(ClaimTypes.Name,               cliente.Nome),
                new Claim(ClaimTypes.Role,               "Cliente"),
                new Claim("cpf",                         cliente.Cpf ?? string.Empty),
                new Claim(JwtRegisteredClaimNames.Jti,   Guid.NewGuid().ToString())
            };

            var token = new JwtSecurityToken(
                issuer: _config["Jwt:Issuer"],
                audience: _config["Jwt:Audience"],
                claims: claims,
                expires: expiracao,
                signingCredentials: creds
            );

            return (new JwtSecurityTokenHandler().WriteToken(token), expiracao);
        }
    }
}
