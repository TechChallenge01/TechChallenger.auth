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

# Extensão serverless do Datadog (métricas/logs de invocação + wrapper que
# ativa o tracer .NET publicado pelo Datadog.Trace.Bundle). Só produz efeito
# quando DD_API_KEY é definida (ver terraform/lambda.tf).
COPY --from=public.ecr.aws/datadog/lambda-extension:latest /opt/extensions/ /opt/extensions/
COPY --from=public.ecr.aws/datadog/lambda-extension:latest /opt/datadog_wrapper /opt/datadog_wrapper

# Amazon.Lambda.AspNetCoreServer.Hosting detecta o ambiente Lambda (via
# AWS_LAMBDA_RUNTIME_API) em tempo de execução e assume o bootstrap do
# Runtime API — não é necessário um LambdaEntryPoint::Method explícito no CMD.
CMD ["TechChallenger.auth"]
