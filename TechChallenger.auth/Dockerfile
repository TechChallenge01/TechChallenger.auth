FROM public.ecr.aws/lambda/dotnet:8 AS base
WORKDIR /var/task

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

COPY TechChallenger.auth.csproj .
RUN dotnet restore "TechChallenger.auth.csproj"

COPY . .
RUN dotnet publish "TechChallenger.auth.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /var/task
COPY --from=build /app/publish .

# Observabilidade: a Lambda roda em subnet privada sem NAT, entao nao ha
# instrumentacao em processo (extensao/tracer Datadog nao conseguiria exportar).
# Os logs vao para o CloudWatch e de la para o Datadog via Log Forwarder
# (terraform/observability.tf).

# Amazon.Lambda.AspNetCoreServer.Hosting detecta o ambiente Lambda (via
# AWS_LAMBDA_RUNTIME_API) em tempo de execução e assume o bootstrap do
# Runtime API — não é necessário um LambdaEntryPoint::Method explícito no CMD.
CMD ["TechChallenger.auth"]
