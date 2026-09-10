resource "aws_security_group" "auth_lambda" {
  name_prefix = "${var.name_prefix}-lambda-"
  description = "ENIs da Lambda de auth"
  vpc_id      = data.aws_vpc.main.id

  egress {
    description = "Saida liberada (RDS na VPC; sem NAT nao ha internet)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name_prefix}-lambda-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "rds_ingress_from_auth_lambda" {
  type                     = "ingress"
  description              = "SQL Server access from auth Lambda"
  from_port                = 1433
  to_port                  = 1433
  protocol                 = "tcp"
  security_group_id        = data.aws_security_group.rds.id
  source_security_group_id = aws_security_group.auth_lambda.id
}

resource "aws_cloudwatch_log_group" "auth" {
  name              = "/aws/lambda/${var.name_prefix}"
  retention_in_days = var.log_retention_days
}

locals {
  # A Lambda de auth roda em subnet privada sem NAT — nao tem egress para o
  # Datadog. A observabilidade dela vai pelo CloudWatch -> Datadog Log Forwarder
  # (ver observability.tf), nao por instrumentacao em processo.
  auth_base_env = {
    ConnectionStrings__DefaultConnection = var.db_connection_string
    Jwt__Key                             = var.jwt_key
    Jwt__Issuer                          = var.jwt_issuer
    Jwt__Audience                        = var.jwt_audience
    Jwt__ExpiracaoHoras                  = var.jwt_expiration_hours
    ASPNETCORE_ENVIRONMENT               = "Production"
  }
}

resource "aws_lambda_function" "auth" {
  function_name = var.name_prefix
  role          = data.aws_iam_role.lab_role.arn
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.auth.repository_url}:${var.image_tag}"
  timeout       = var.lambda_timeout_seconds
  memory_size   = var.lambda_memory_mb
  publish       = true

  vpc_config {
    subnet_ids         = data.aws_subnets.private.ids
    security_group_ids = [aws_security_group.auth_lambda.id]
  }

  environment {
    variables = local.auth_base_env
  }

  tags = {
    Name = var.name_prefix
  }

  depends_on = [aws_cloudwatch_log_group.auth]
}
