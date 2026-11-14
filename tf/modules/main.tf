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
resource "aws_iam_role_policy_attachment" "basic_execution" {
  role       = aws_iam_role.main.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}


# Grafana Cloud に OTLP で送るための Authorization ヘッダーの値（Basic <base64(スタックの ID:トークン)>）。
# SSM Parameter Store に置かれている（このリポジトリの外で管理する）。
# Lambda の Collector レイヤーは SSM を読めないため、ここで読んで Lambda の環境変数に渡す
data "aws_ssm_parameter" "grafana_otlp_auth" {
  name = var.grafana_otlp_auth_parameter
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
  # X-Ray にはトレースを送らない（Grafana Cloud に送る）。
  # ブロックを消すだけでは今の設定（Active）が残るため、PassThrough を明示する
  tracing_config {
    mode = "PassThrough"
  }
  environment {
    variables = {
      "AWS_LAMBDA_EXEC_WRAPPER" = "/opt/otel-handler"
      # zipに同梱した collector.yaml を使う(/var/task はLambdaのコード展開先)
      "OPENTELEMETRY_COLLECTOR_CONFIG_URI" = "/var/task/collector.yaml"
      "OTEL_SERVICE_NAME"                  = var.appname
      # 環境。Grafana で絞り込むために付ける（このアプリは本番だけ）。
      # deployment.environment.name は新しいセマンティック規約の名前で、古い名前も一緒に付けておく
      "OTEL_RESOURCE_ATTRIBUTES" = "deployment.environment.name=prod,deployment.environment=prod"
      "OTEL_TRACES_EXPORTER"     = "otlp"
      "OTEL_METRICS_EXPORTER"    = "otlp"
      # メトリクスは SDK の既定の cumulative（累積値）で送る（Grafana Cloud は Prometheus 互換で累積値を前提にする）。
      # 1日1回の実行でほぼ毎回コールドスタートになり、カウンタは毎回 0 から数え直すため、
      # Grafana では increase() ではなく、その日の値（例: max_over_time(...[1d])）で見る
      # collector.yaml が読む、Grafana Cloud の OTLP の送信先と Authorization ヘッダーの値
      "GRAFANA_CLOUD_OTLP_ENDPOINT" = var.grafana_otlp_endpoint
      "GRAFANA_CLOUD_OTLP_AUTH"     = data.aws_ssm_parameter.grafana_otlp_auth.value
      "ANNICT_TOKEN"                = var.annict_token
      "NOTIFY_API_KEY"              = var.notify_api_key
      "NOTIFY_ENDPOINT"             = var.notify_endpoint
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
