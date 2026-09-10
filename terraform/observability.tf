# ---------------------------------------------------------------------------
# Observabilidade da camada serverless (auth) — Datadog Log Forwarder.
#
# A Lambda de auth roda em subnet privada SEM NAT: nao consegue exportar nada
# para o Datadog por conta propria. O padrao recomendado pela AWS e pela
# Datadog e um "forwarder": uma Lambda FORA da VPC (com egress) inscrita nos
# log groups do CloudWatch, que le os eventos e os encaminha para o Datadog.
#
# So e criado quando ha `datadog_api_key`. Sem a key, a observabilidade da
# auth fica pelo CloudWatch (metricas nativas de invocacao do Lambda + o log
# de acesso do API Gateway em JSON).
# ---------------------------------------------------------------------------

locals {
  # "tem key?" e um booleano que nao revela a key -> nonsensitive e seguro aqui
  # (necessario para usar em for_each dos subscription filters).
  datadog_enabled = nonsensitive(var.datadog_api_key) != ""

  # Log groups encaminhados para o Datadog.
  forwarded_log_groups = local.datadog_enabled ? {
    auth       = aws_cloudwatch_log_group.auth.name
    authorizer = aws_cloudwatch_log_group.authorizer.name
    apigateway = aws_cloudwatch_log_group.gw_access.name
  } : {}
}

resource "aws_lambda_function" "datadog_forwarder" {
  count         = local.datadog_enabled ? 1 : 0
  function_name = "${var.name_prefix}-dd-forwarder"
  description   = "Encaminha logs do CloudWatch (auth + API Gateway) para o Datadog"
  role          = data.aws_iam_role.lab_role.arn
  runtime       = "python3.12"
  handler       = "lambda_function.lambda_handler"
  timeout       = 120
  memory_size   = 256

  # Zip publicado pela Datadog (bucket publico). Fica FORA de VPC -> tem egress.
  s3_bucket = "datadog-cloudformation-template"
  s3_key    = "aws/forwarder/latest.zip"

  environment {
    variables = {
      DD_API_KEY          = var.datadog_api_key
      DD_SITE             = var.datadog_site
      DD_ENHANCED_METRICS = "false"
      DD_TAGS             = "env:${var.datadog_env},service:${var.name_prefix}"
    }
  }

  depends_on = [aws_cloudwatch_log_group.datadog_forwarder]
}

resource "aws_cloudwatch_log_group" "datadog_forwarder" {
  count             = local.datadog_enabled ? 1 : 0
  name              = "/aws/lambda/${var.name_prefix}-dd-forwarder"
  retention_in_days = var.log_retention_days
}

# Permite que o CloudWatch Logs invoque o forwarder.
resource "aws_lambda_permission" "datadog_forwarder_from_logs" {
  count         = local.datadog_enabled ? 1 : 0
  statement_id  = "AllowCloudWatchLogsInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.datadog_forwarder[0].function_name
  principal     = "logs.amazonaws.com"
  source_arn    = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:*"
}

# Inscreve cada log group no forwarder (filter_pattern vazio = todos os eventos).
resource "aws_cloudwatch_log_subscription_filter" "to_datadog" {
  for_each        = local.forwarded_log_groups
  name            = "${var.name_prefix}-${each.key}-to-datadog"
  log_group_name  = each.value
  filter_pattern  = ""
  destination_arn = aws_lambda_function.datadog_forwarder[0].arn
  depends_on      = [aws_lambda_permission.datadog_forwarder_from_logs]
}
