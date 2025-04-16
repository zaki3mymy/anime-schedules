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

# GitHubとAWSをOIDCで連携するようにIDプロバイダを作成してある。
# それにGitHubOIDCという名前のロールを割り当てているので、そのロールに
# このファイルで作成・更新（削除）するリソースを操作するためのポリシーを割り当てる。
resource "aws_iam_policy" "github_actions_oidc" {
  name        = "${var.appname}-github-actions-oidc"
  description = "Policy for GitHub Actions OIDC"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:UpdateRole",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:PassRole",
          "iam:CreatePolicy",
          "iam:DeletePolicy",
          "iam:UpdatePolicy",
          "lambda:CreateFunction",
          "lambda:DeleteFunction",
          "lambda:UpdateFunctionCode",
          "lambda:UpdateFunctionConfiguration",
          "lambda:AddPermission",
          "lambda:RemovePermission",
          "logs:CreateLogGroup",
          "logs:DeleteLogGroup",
          "logs:PutRetentionPolicy",
          "events:PutRule",
          "events:DeleteRule",
          "events:PutTargets",
          "events:RemoveTargets",
          "resource-groups:CreateGroup",
          "resource-groups:DeleteGroup",
          "resource-groups:Tag",
          "resource-groups:Untag",
          "resource-groups:UpdateGroupQuery"
        ]
        Resource = "*"
      }
    ]
  })
}
resource "aws_iam_policy_attachment" "github_actions_oidc" {
  name       = "${var.appname}-github-actions-oidc-attachment"
  policy_arn = aws_iam_policy.github_actions_oidc.arn
  roles      = ["GitHubOIDC"]
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
