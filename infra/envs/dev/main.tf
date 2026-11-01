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
    key            = "dev/network/terraform.tfstate"
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
      ManagedBy   = "terraform"
    }
  }
}

variable "enable_nat" {
  description = "Create the NAT gateway (costs money; only needed while servers need the internet)"
  type        = bool
  default     = false
}

module "vpc" {
  source = "../../modules/vpc"

  name       = "stk-dev"
  cidr       = "10.20.0.0/16"
  azs        = ["eu-west-2a", "eu-west-2b"]
  enable_nat = var.enable_nat
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "web_subnet_ids" {
  value = module.vpc.web_subnet_ids
}

output "app_subnet_ids" {
  value = module.vpc.app_subnet_ids
}

output "data_subnet_ids" {
  value = module.vpc.data_subnet_ids
}
