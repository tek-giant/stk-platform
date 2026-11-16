# Things installed INSIDE the EKS cluster (controllers), plus the AWS
# permissions they need. Kept apart from dev-eks so the cluster is fully
# built before Terraform tries to talk to it.
terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.95"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.17" # v3 changed the syntax; moving to it is a deliberate upgrade
    }
  }

  backend "s3" {
    bucket         = "stk-tfstate-743978812281"
    key            = "dev/eks-addons/terraform.tfstate"
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
      Layer       = "eks-addons"
      ManagedBy   = "terraform"
    }
  }
}

locals {
  cluster_name = "stk-dev-eks"
}

# Look up the running cluster: its address, certificate and VPC.
data "aws_eks_cluster" "this" {
  name = local.cluster_name
}

# Helm installs software into the cluster. It logs in the same way kubectl
# does: "aws eks get-token", using your AWS_PROFILE (your SSO role).
provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.this.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", local.cluster_name, "--region", "eu-west-2"]
    }
  }
}
