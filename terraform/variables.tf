variable "aws_region" {
  description = "Regiao AWS (deve ser a mesma da infra compartilhada — EKS/RDS/ECR)"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefixo/tag comum a toda a infra do Tech Challenge"
  type        = string
  default     = "techchallenge"
}

variable "name_prefix" {
  description = "Prefixo dos recursos criados por este repositorio"
  type        = string
  default     = "techchallenge-auth"
}

variable "ecr_repository_name" {
  description = "Nome do repositorio ECR da imagem da Lambda (deve bater com ECR_REPOSITORY no cd.yml)"
  type        = string
  default     = "techchallenge-auth"
}

variable "image_tag" {
  description = "Tag da imagem no ECR que a Lambda deve rodar. A esteira sobrescreve com o SHA do commit (TF_VAR_image_tag)."
  type        = string
  default     = "latest"
}

variable "vpc_name" {
  description = "Tag Name da VPC compartilhada"
  type        = string
  default     = "techchallenge-vpc"
}

variable "private_subnet_name_pattern" {
  description = "Padrao da tag Name das subnets privadas onde a Lambda e o VPC Link ficam"
  type        = string
  default     = "techchallenge-private-*"
}

variable "rds_sg_name" {
  description = "Tag Name do security group do RDS SQL Server compartilhado"
  type        = string
  default     = "techchallenge-sqlserver-sg"
}

variable "eks_cluster_name" {
  description = "Nome do cluster EKS que roda a TechChallenge API"
  type        = string
  default     = "techchallenge"
}

variable "app_node_port" {
  description = "NodePort em que o Service da TechChallenge API responde nos nodes do EKS (k8s/service.yaml)"
  type        = number
  default     = 30080
}

variable "db_connection_string" {
  description = "Connection string do RDS SQL Server (mesma base da TechChallenge API; a auth so faz leitura)"
  type        = string
  sensitive   = true
}

variable "jwt_key" {
  description = "Chave HMAC (HS256) — IDENTICA a Jwt:Key da TechChallenge API. Usada pela Lambda de auth e pelo authorizer."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.jwt_key) >= 32
    error_message = "jwt_key deve ter no minimo 32 caracteres."
  }
}

variable "jwt_issuer" {
  description = "Emissor do JWT (claim iss)"
  type        = string
  default     = "TechChallenger"
}

variable "jwt_audience" {
  description = "Audiencia do JWT (claim aud)"
  type        = string
  default     = "TechChallenger"
}

variable "jwt_expiration_hours" {
  description = "Validade do token emitido, em horas (Jwt:ExpiracaoHoras)"
  type        = string
  default     = "8"
}

variable "datadog_api_key" {
  description = "API key do Datadog. Vazio = extensao nao instrumenta (a Lambda roda em subnet privada sem NAT, entao sem VPC endpoint/NAT o Datadog nao consegue exportar de qualquer forma)."
  type        = string
  sensitive   = true
  default     = ""
}

variable "datadog_site" {
  description = "Site do Datadog (datadoghq.com, datadoghq.eu, us5.datadoghq.com, ...)"
  type        = string
  default     = "datadoghq.com"
}

variable "datadog_env" {
  description = "Valor de DD_ENV (unified service tagging)"
  type        = string
  default     = "prod"
}

variable "lambda_memory_mb" {
  description = "Memoria da Lambda de auth (MB)"
  type        = number
  default     = 512
}

variable "lambda_timeout_seconds" {
  description = "Timeout da Lambda de auth (s)"
  type        = number
  default     = 30
}

variable "authorizer_result_ttl_seconds" {
  description = "Cache do resultado do Lambda authorizer no API Gateway (s). 0 desliga o cache."
  type        = number
  default     = 300
}

variable "log_retention_days" {
  description = "Retencao dos log groups do CloudWatch (Lambdas + acesso do API Gateway)"
  type        = number
  default     = 14
}
