resource "aws_apigatewayv2_api" "gw" {
  name          = "${var.name_prefix}-gateway"
  protocol_type = "HTTP"
  description   = "Tech Challenge - gateway de autenticacao e roteamento"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"]
    allow_headers = ["authorization", "content-type"]
    max_age       = 300
  }
}

resource "aws_cloudwatch_log_group" "gw_access" {
  name              = "/aws/apigateway/${var.name_prefix}"
  retention_in_days = var.log_retention_days
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.gw.id
  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.gw_access.arn
    format = jsonencode({
      requestId          = "$context.requestId"
      requestTime        = "$context.requestTime"
      httpMethod         = "$context.httpMethod"
      routeKey           = "$context.routeKey"
      path               = "$context.path"
      status             = "$context.status"
      protocol           = "$context.protocol"
      responseLatency    = "$context.responseLatency"
      integrationLatency = "$context.integrationLatency"
      integrationStatus  = "$context.integrationStatus"
      sourceIp           = "$context.identity.sourceIp"
      userAgent          = "$context.identity.userAgent"
      authorizerError    = "$context.authorizer.error"
      clienteId          = "$context.authorizer.sub"
    })
  }

  default_route_settings {
    detailed_metrics_enabled = true
    throttling_burst_limit   = 50
    throttling_rate_limit    = 100
  }
}

resource "aws_apigatewayv2_integration" "auth" {
  api_id                 = aws_apigatewayv2_api.gw.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.auth.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "auth_cpf" {
  api_id    = aws_apigatewayv2_api.gw.id
  route_key = "POST /auth/cpf"
  target    = "integrations/${aws_apigatewayv2_integration.auth.id}"
}

resource "aws_apigatewayv2_route" "health" {
  api_id    = aws_apigatewayv2_api.gw.id
  route_key = "GET /health"
  target    = "integrations/${aws_apigatewayv2_integration.auth.id}"
}

resource "aws_lambda_permission" "auth_from_gw" {
  statement_id  = "AllowInvokeFromHttpApi"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.auth.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.gw.execution_arn}/*/*"
}

resource "aws_apigatewayv2_authorizer" "jwt_hs256" {
  api_id                            = aws_apigatewayv2_api.gw.id
  name                              = "${var.name_prefix}-hs256"
  authorizer_type                   = "REQUEST"
  authorizer_uri                    = aws_lambda_function.authorizer.invoke_arn
  authorizer_payload_format_version = "2.0"
  enable_simple_responses           = true
  identity_sources                  = ["$request.header.Authorization"]
  authorizer_result_ttl_in_seconds  = var.authorizer_result_ttl_seconds
}

resource "aws_lambda_permission" "authorizer_from_gw" {
  statement_id  = "AllowInvokeAuthorizerFromHttpApi"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.authorizer.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.gw.execution_arn}/authorizers/${aws_apigatewayv2_authorizer.jwt_hs256.id}"
}

resource "aws_security_group" "vpc_link" {
  name_prefix = "${var.name_prefix}-vpclink-"
  description = "ENIs do VPC Link do API Gateway"
  vpc_id      = data.aws_vpc.main.id

  egress {
    description = "Saida para o NLB interno / nodes do EKS"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [data.aws_vpc.main.cidr_block]
  }

  tags = {
    Name = "${var.name_prefix}-vpclink-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_apigatewayv2_vpc_link" "eks" {
  name               = "${var.name_prefix}-vpclink"
  security_group_ids = [aws_security_group.vpc_link.id]
  subnet_ids         = data.aws_subnets.private.ids
}

resource "aws_apigatewayv2_integration" "app" {
  api_id                 = aws_apigatewayv2_api.gw.id
  integration_type       = "HTTP_PROXY"
  integration_method     = "ANY"
  integration_uri        = aws_lb_listener.app.arn
  connection_type        = "VPC_LINK"
  connection_id          = aws_apigatewayv2_vpc_link.eks.id
  payload_format_version = "1.0"

  request_parameters = {
    "append:header.x-request-id" = "$context.requestId"
  }
}

resource "aws_apigatewayv2_route" "app_protected" {
  api_id             = aws_apigatewayv2_api.gw.id
  route_key          = "ANY /api/{proxy+}"
  target             = "integrations/${aws_apigatewayv2_integration.app.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.jwt_hs256.id
}
