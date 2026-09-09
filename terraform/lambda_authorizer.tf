data "archive_file" "authorizer" {
  type        = "zip"
  source_dir  = "${path.module}/src-authorizer"
  output_path = "${path.module}/build/authorizer.zip"
}

resource "aws_cloudwatch_log_group" "authorizer" {
  name              = "/aws/lambda/${var.name_prefix}-authorizer"
  retention_in_days = var.log_retention_days
}

resource "aws_lambda_function" "authorizer" {
  function_name    = "${var.name_prefix}-authorizer"
  role             = data.aws_iam_role.lab_role.arn
  runtime          = "nodejs20.x"
  handler          = "index.handler"
  filename         = data.archive_file.authorizer.output_path
  source_code_hash = data.archive_file.authorizer.output_base64sha256
  timeout          = 10
  memory_size      = 128

  environment {
    variables = {
      JWT_KEY      = var.jwt_key
      JWT_ISSUER   = var.jwt_issuer
      JWT_AUDIENCE = var.jwt_audience
    }
  }

  tags = {
    Name = "${var.name_prefix}-authorizer"
  }

  depends_on = [aws_cloudwatch_log_group.authorizer]
}
