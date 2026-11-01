terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.70"
    }
  }

  backend "s3" {
    bucket         = "stk-tfstate-743978812281"
    key            = "dev/web/terraform.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "stk-tf-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = "eu-west-2"

  default_tags {
    tags = {
      Project     = "stk-platform"
      Environment = "dev"
      Layer       = "web"
      ManagedBy   = "terraform"
    }
  }
}

data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "stk-tfstate-743978812281"
    key    = "dev/network/terraform.tfstate"
    region = "eu-west-2"
  }
}

data "terraform_remote_state" "app" {
  backend = "s3"
  config = {
    bucket = "stk-tfstate-743978812281"
    key    = "dev/app/terraform.tfstate"
    region = "eu-west-2"
  }
}

locals {
  name              = "stk-dev"
  vpc_id            = data.terraform_remote_state.network.outputs.vpc_id
  public_subnet_ids = data.terraform_remote_state.network.outputs.public_subnet_ids
  web_subnet_ids    = data.terraform_remote_state.network.outputs.web_subnet_ids
  api_dns           = data.terraform_remote_state.app.outputs.alb_dns_name
}

data "aws_vpc" "main" {
  id = local.vpc_id
}

data "aws_ecr_repository" "web" {
  name = "stk/web"
}

data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}
