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
    key            = "dev/app/terraform.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "stk-tf-locks"
    encrypt        = true
    profile        = "stk-platform"
  }
}

provider "aws" {
  region  = "eu-west-2"
  profile = "stk-platform"

  default_tags {
    tags = {
      Project     = "stk-platform"
      Environment = "dev"
      Layer       = "app"
      ManagedBy   = "terraform"
    }
  }
}

data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket  = "stk-tfstate-743978812281"
    key     = "dev/network/terraform.tfstate"
    region  = "eu-west-2"
    profile = "stk-platform"
  }
}

locals {
  name               = "stk-dev"
  vpc_id             = data.terraform_remote_state.network.outputs.vpc_id
  app_subnet_ids     = data.terraform_remote_state.network.outputs.app_subnet_ids
  ecr_repository_url = data.terraform_remote_state.network.outputs.ecr_repository_url
}

data "aws_vpc" "main" {
  id = local.vpc_id
}
