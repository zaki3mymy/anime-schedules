terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.71"
    }
  }

  required_version = ">= 1.7.0"

  # `terraform init`のときに`-backend-config`で以下の値を設定する
  # -backend-config="bucket=<BUCKET_NAME>"
  # -backend-config="key=anime-schedules/terraform.tfstate"
  # -backend-config="region=ap-northeast-1"
  backend "s3" {
  }
}

provider "aws" {
  region = "ap-northeast-1"
  default_tags {
    tags = {
      "AppName" = local.appname
    }
  }
}

locals {
  appname = "anime-schedules"
  # OTel Lambdaレイヤー: Python計装レイヤー + コレクターレイヤー（どちらもコミュニティ製）
  # バージョンは https://github.com/open-telemetry/opentelemetry-lambda/releases で確認
  # （layer-python/<version>・layer-collector/<version> のタグ）
  # コレクターは OTLP を受けて、Grafana Cloud に otlphttp で送る（src/anime_schedules/collector.yaml）
  otel_layer_arns = [
    "arn:aws:lambda:ap-northeast-1:184161586896:layer:opentelemetry-python-0_21_0:1",
    "arn:aws:lambda:ap-northeast-1:184161586896:layer:opentelemetry-collector-amd64-0_24_0:1",
  ]

  # Grafana Cloud の OTLP の送信先（スタックの OTLP の URL に /otlp を付けたもの）。
  # otlphttp exporter はこの後ろに /v1/traces・/v1/metrics を付けて送る
  grafana_otlp_endpoint = "https://otlp-gateway-prod-ap-northeast-0.grafana.net/otlp"
  # Grafana Cloud に送るための Authorization ヘッダーの値を置いた SSM パラメータ（このリポジトリの外で作る）
  grafana_otlp_auth_parameter = "/app/grafana/prod/otlp_auth"
}

module "main" {
  source = "./modules"

  appname         = local.appname
  annict_token    = var.annict_token
  notify_api_key  = var.notify_api_key
  notify_endpoint = var.notify_endpoint
  otel_layer_arns = local.otel_layer_arns

  grafana_otlp_endpoint       = local.grafana_otlp_endpoint
  grafana_otlp_auth_parameter = local.grafana_otlp_auth_parameter
}
