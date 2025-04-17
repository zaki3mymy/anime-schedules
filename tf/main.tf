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
}

module "main" {
  source = "./modules"

  appname      = local.appname
  annict_token = var.annict_token
  line_token   = var.line_token
  line_user_id = var.line_user_id
}
