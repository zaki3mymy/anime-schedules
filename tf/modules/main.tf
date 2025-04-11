# IAM
resource "aws_iam_role" "main" {
  name        = "${var.appname}-role"
  description = "Role for ${var.appname}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Effect = "Allow"
        Sid    = ""
      },
    ]
  })
}
resource "aws_iam_policy_attachment" "main" {
  name       = "${var.appname}-policy-attachment"
  roles      = [aws_iam_role.main.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Lambda
data "archive_file" "main" {
  type        = "zip"
  source_dir  = "${path.root}/../src/anime_schedules/"
  output_path = "${path.root}/../dist/src.zip"
}
resource "aws_lambda_function" "main" {
  function_name    = var.appname
  role             = aws_iam_role.main.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.13"
  filename         = data.archive_file.main.output_path
  source_code_hash = data.archive_file.main.output_base64sha256
  environment {
    variables = {
      "ANNICT_TOKEN" = var.annict_token
      "LINE_TOKEN"   = var.line_token
      "LINE_USER_ID" = var.line_user_id
    }
  }
  timeout = 30
  logging_config {
    log_format = "JSON"
    application_log_level = "INFO"
    system_log_level = "INFO"
  }
}
resource "aws_lambda_permission" "main" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.main.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.main.arn
}

# CloudWatch Logs
resource "aws_cloudwatch_log_group" "main" {
  name              = "/aws/lambda/${aws_lambda_function.main.function_name}"
  retention_in_days = 14
}

# EventBridge
resource "aws_cloudwatch_event_rule" "main" {
  name                = "${var.appname}-rule"
  description         = "Send Anime Schedules every 16:00."
  # UTCでcron式を書くことに注意
  schedule_expression = "cron(0 7 * * ? *)"
}
resource "aws_cloudwatch_event_target" "main" {
  rule      = aws_cloudwatch_event_rule.main.name
  target_id = "${var.appname}-rule"
  arn       = aws_lambda_function.main.arn
}

# ResourceGroup
resource "aws_resourcegroups_group" "main" {
  name = "${var.appname}-resourcegroup"
  resource_query {
    query = jsonencode({
      "ResourceTypeFilters" : [
        "AWS::AllSupported"
      ],
      "TagFilters" : [
        {
          "Key" : "AppName",
          "Values" : [var.appname]
        }
      ]
    })
  }
}
