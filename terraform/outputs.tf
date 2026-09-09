output "api_base_url" {
  description = "URL base do API Gateway (stage $default)"
  value       = aws_apigatewayv2_stage.default.invoke_url
}

output "auth_endpoint" {
  description = "Endpoint publico de autenticacao por CPF"
  value       = "${aws_apigatewayv2_stage.default.invoke_url}auth/cpf"
}

output "health_endpoint" {
  description = "Healthcheck da Lambda de auth"
  value       = "${aws_apigatewayv2_stage.default.invoke_url}health"
}

output "protected_api_base" {
  description = "Prefixo das rotas da TechChallenge API protegidas pelo authorizer (exige Authorization: Bearer <jwt>)"
  value       = "${aws_apigatewayv2_stage.default.invoke_url}api"
}

output "ecr_repository_url" {
  description = "Repositorio ECR da imagem da Lambda de auth"
  value       = aws_ecr_repository.auth.repository_url
}

output "auth_lambda_name" {
  description = "Nome da funcao Lambda de auth (usado pela esteira em update-function-code, se aplicavel)"
  value       = aws_lambda_function.auth.function_name
}

output "authorizer_lambda_name" {
  description = "Nome da funcao do Lambda authorizer"
  value       = aws_lambda_function.authorizer.function_name
}

output "internal_nlb_dns" {
  description = "DNS do NLB interno na frente do EKS (nao acessivel fora da VPC)"
  value       = aws_lb.internal.dns_name
}

output "vpc_link_id" {
  description = "ID do VPC Link do API Gateway"
  value       = aws_apigatewayv2_vpc_link.eks.id
}
