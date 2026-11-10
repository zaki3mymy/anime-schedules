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
  # OTel Lambdaレイヤー: Python計装レイヤー（コミュニティ製） + ADOTコレクターレイヤー（AWS公式）
  # Python計装レイヤーのバージョンは https://github.com/open-telemetry/opentelemetry-lambda/releases で確認
  # ADOTコレクターレイヤーのバージョンは https://aws-otel.github.io/docs/getting-started/lambda で確認
  # awsxray/awsemfエクスポーターを使うため、コレクターはADOT版（901920570463）を使う
  # コミュニティ製コレクターレイヤー（184161586896）にはAWS固有エクスポーターが含まれていない
  otel_layer_arns = [
    "arn:aws:lambda:ap-northeast-1:184161586896:layer:opentelemetry-python-0_21_0:1",
    "arn:aws:lambda:ap-northeast-1:901920570463:layer:aws-otel-collector-amd64-ver-0-117-0:1",
  ]
}

module "main" {
  source = "./modules"

  appname         = local.appname
  annict_token    = var.annict_token
  notify_api_key  = var.notify_api_key
  notify_endpoint = var.notify_endpoint
  otel_layer_arns = local.otel_layer_arns
}
