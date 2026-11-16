# External Secrets Operator
# Copies secrets from AWS Secrets Manager into Kubernetes Secrets, so pods can
# use the database password without it ever being written into Git or an image.

variable "external_secrets_chart_version" {
  description = "Helm chart version of External Secrets. Find the latest with: helm search repo external-secrets/external-secrets"
  type        = string
}

data "aws_caller_identity" "current" {}

# 1. An IAM role the operator's pod can use (Pod Identity), allowed to READ only
#    the RDS-managed database secrets. RDS names them "rds!db-<id>"; a new one is
#    created each time the database is rebuilt, so the pattern keeps working.
module "external_secrets_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.4"

  name = "stk-dev-external-secrets"

  attach_external_secrets_policy = true
  external_secrets_secrets_manager_arns = [
    "arn:aws:secretsmanager:eu-west-2:${data.aws_caller_identity.current.account_id}:secret:rds!db-*",
  ]
  external_secrets_create_permission = false # read only: it can't create or change secrets

  associations = {
    operator = {
      cluster_name    = local.cluster_name
      namespace       = "external-secrets"
      service_account = "external-secrets"
    }
  }
}

# 2. The operator itself, from its official Helm chart, in its own namespace.
resource "helm_release" "external_secrets" {
  name             = "external-secrets"
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  version          = var.external_secrets_chart_version
  namespace        = "external-secrets"
  create_namespace = true

  set {
    name  = "installCRDs"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "external-secrets"
  }

  depends_on = [module.external_secrets_pod_identity]
}

output "external_secrets_role_arn" {
  description = "IAM role External Secrets uses through Pod Identity"
  value       = module.external_secrets_pod_identity.iam_role_arn
}
