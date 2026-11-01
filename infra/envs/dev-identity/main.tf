terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.70"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  backend "s3" {
    bucket         = "stk-tfstate-743978812281"
    key            = "dev/identity/terraform.tfstate"
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
      Layer       = "identity"
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

locals {
  name           = "stk-dev"
  vpc_id         = data.terraform_remote_state.network.outputs.vpc_id
  app_subnet_ids = data.terraform_remote_state.network.outputs.app_subnet_ids
  kms_key_arn    = data.terraform_remote_state.network.outputs.kms_key_arn
}
