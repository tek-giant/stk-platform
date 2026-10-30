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
    key            = "dev/data/terraform.tfstate"
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
      Layer       = "data"
      ManagedBy   = "terraform"
    }
  }
}

# Read the network and key built earlier
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
  name            = "stk-dev"
  vpc_id          = data.terraform_remote_state.network.outputs.vpc_id
  data_subnet_ids = data.terraform_remote_state.network.outputs.data_subnet_ids
  kms_key_arn     = data.terraform_remote_state.network.outputs.kms_key_arn
}
