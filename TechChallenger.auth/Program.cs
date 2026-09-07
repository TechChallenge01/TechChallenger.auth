using Microsoft.EntityFrameworkCore;
using TechChallenger.auth.Data;
using TechChallenger.auth.Extensions;
using TechChallenger.auth.Services;

var builder = WebApplication.CreateBuilder(args);

// Empacotado como imagem de container e executado via API Gateway (proxy HTTP API) -> Lambda.
builder.Services.AddAWSLambdaHosting(LambdaEventSource.HttpApi);

builder.Services.AddEndpoints(System.Reflection.Assembly.GetExecutingAssembly());

builder.Services.AddSingleton<IJwtTokenService, JwtTokenService>();

builder.Services.AddDbContext<AuthDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection"), sqlOptions =>
    {
        sqlOptions.EnableRetryOnFailure(maxRetryCount: 3, maxRetryDelay: TimeSpan.FromSeconds(5), errorNumbersToAdd: null);
    }));

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options => options.SwaggerDoc("v1", new() { Title = "TechChallenge Auth", Version = "v1" }));

var app = builder.Build();

app.UseSwagger();
app.UseSwaggerUI(options => options.SwaggerEndpoint("/swagger/v1/swagger.json", "TechChallenge Auth v1"));

app.MapEndpoints();

app.MapGet("/health", () => Results.Ok(new { status = "TechChallenge Auth - Running" }));

app.Run();

public partial class Program() { }
