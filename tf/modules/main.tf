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
# aws_iam_policy_attachment はアカウント全体でポリシーのアタッチ先を排他的に管理してしまい、
# 同じマネージドポリシーを使う他プロジェクトのロールからデタッチしようとするため、ロール単位で管理する
resource "aws_iam_role_policy_attachment" "basic_execution" {
  role       = aws_iam_role.main.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "xray" {
  role       = aws_iam_role.main.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}

# awsemf エクスポーターで CloudWatch にメトリクスを送信するため
resource "aws_iam_role_policy_attachment" "cloudwatch_metrics" {
  role       = aws_iam_role.main.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
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
  # zipには opentelemetry パッケージが含まれないため、Layerから提供する
  # AWS_LAMBDA_EXEC_WRAPPER（下記environment）でPython計装レイヤーがlambda_handlerをラップする
  layers = var.otel_layer_arns
  tracing_config {
    mode = "Active"
  }
  environment {
    variables = {
      "AWS_LAMBDA_EXEC_WRAPPER" = "/opt/otel-handler"
      # zipに同梱した collector.yaml を使う(/var/task はLambdaのコード展開先)
      "OPENTELEMETRY_COLLECTOR_CONFIG_URI" = "/var/task/collector.yaml"
      "OTEL_SERVICE_NAME"                  = var.appname
      "OTEL_TRACES_EXPORTER"               = "otlp"
      "OTEL_METRICS_EXPORTER"              = "otlp"
      # 1日1回の実行でほぼ毎回コールドスタートになるため、累積値だと awsemf が
      # 初回データポイントを基準値として捨ててしまう。DELTA で送信する
      "OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE" = "DELTA"
      "ANNICT_TOKEN"                                      = var.annict_token
      "NOTIFY_API_KEY"                                    = var.notify_api_key
      "NOTIFY_ENDPOINT"                                   = var.notify_endpoint
    }
  }
  timeout = 30
  logging_config {
    log_format            = "JSON"
    application_log_level = "INFO"
    system_log_level      = "INFO"
  }
}
resource "aws_lambda_permission" "main" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.main.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.main.arn
}
resource "aws_lambda_function_event_invoke_config" "main" {
  function_name = aws_lambda_function.main.function_name
  # 設定「非同期呼び出し→再試行」を0回にするための設定
  # たぶんダメなときは何度やってもダメなので・・・。
  maximum_retry_attempts = 0
}

# CloudWatch Logs
resource "aws_cloudwatch_log_group" "main" {
  name              = "/aws/lambda/${aws_lambda_function.main.function_name}"
  retention_in_days = 14
}

# EventBridge
resource "aws_cloudwatch_event_rule" "main" {
  name        = "${var.appname}-rule"
  description = "Send Anime Schedules every 18:00."
  # UTCでcron式を書くことに注意
  schedule_expression = "cron(0 9 * * ? *)"
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
