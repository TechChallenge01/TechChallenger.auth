using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TechChallenger.auth.Data;
using TechChallenger.auth.Dtos;
using TechChallenger.auth.Services;
using TechChallenger.auth.ValueObjects;

namespace TechChallenger.auth.EndPoints.Auth
{
    public class Authenticate : IEndpoint
    {
        public void MapEndpoint(IEndpointRouteBuilder app)
        {
            app.MapPost("/auth/cpf", async (AuthDbContext db, IJwtTokenService jwtTokenService, [FromBody] AutenticarRequestDTO request, CancellationToken ct) =>
            {
                Cpf cpf;
                try
                {
                    cpf = new Cpf(request.Cpf);
                }
                catch (ArgumentException ex)
                {
                    return Results.BadRequest(new { message = ex.Message });
                }

                var cliente = await db.Clientes.AsNoTracking()
                    .FirstOrDefaultAsync(c => c.Cpf == cpf.Valor, ct);

                if (cliente is null)
                    return Results.NotFound(new { message = "Cliente não encontrado para o CPF informado." });

                if (!cliente.Ativo)
                    return Results.Json(new { message = "Cliente inativo." }, statusCode: StatusCodes.Status403Forbidden);

                var (token, expiracao) = jwtTokenService.GerarToken(cliente);

                var response = new AutenticarResponseDTO
                {
                    Token = token,
                    Expiracao = expiracao,
                    ClienteId = cliente.Id,
                    Nome = cliente.Nome
                };

                return Results.Ok(response);
            })
            .WithName("AutenticarPorCpf")
            .WithTags("Auth")
            .Produces<AutenticarResponseDTO>(StatusCodes.Status200OK)
            .ProducesProblem(StatusCodes.Status400BadRequest)
            .ProducesProblem(StatusCodes.Status403Forbidden)
            .ProducesProblem(StatusCodes.Status404NotFound);
        }
    }
}
