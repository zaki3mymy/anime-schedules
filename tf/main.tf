terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.92"
    }
  }

  required_version = ">= 1.2.0"

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
  # ADOT Python Layer。バージョンは以下を参照して更新する
  # https://aws-otel.github.io/docs/getting-started/lambda/lambda-python
  otel_layer_arn = "arn:aws:lambda:ap-northeast-1:901920570463:layer:aws-otel-python-amd64-ver-1-32-0:2"
}

module "main" {
  source = "./modules"

  appname         = local.appname
  annict_token    = var.annict_token
  notify_api_key  = var.notify_api_key
  notify_endpoint = var.notify_endpoint
  otel_layer_arn  = local.otel_layer_arn
}
