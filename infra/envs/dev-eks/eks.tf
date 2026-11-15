# The EKS cluster and its worker nodes, using the community EKS module.
# Pinned to v20: v21 renamed many inputs, so moving to it is a deliberate upgrade.
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = local.cluster_name
  cluster_version = var.cluster_version

  # Nodes and the control plane's network interfaces live in the private app subnets.
  vpc_id     = local.vpc_id
  subnet_ids = local.app_subnet_ids

  # kubectl works from your laptop, but only from the IP addresses you list.
  cluster_endpoint_public_access       = true
  cluster_endpoint_public_access_cidrs = var.admin_cidrs
  cluster_endpoint_private_access      = true

  # Whoever runs terraform apply (your SSO role) becomes a cluster admin.
  enable_cluster_creator_admin_permissions = true

  # Encrypt Kubernetes Secrets with the platform's existing KMS key.
  create_kms_key = false
  cluster_encryption_config = {
    resources        = ["secrets"]
    provider_key_arn = local.kms_key_arn
  }

  # Control plane logs to CloudWatch, kept for a week.
  cluster_enabled_log_types              = ["api", "audit", "authenticator"]
  cloudwatch_log_group_retention_in_days = 7

  # Core add-ons, managed by AWS.
  cluster_addons = {
    vpc-cni = {
      most_recent    = true
      before_compute = true # networking must exist before the nodes join
    }
    kube-proxy             = { most_recent = true }
    coredns                = { most_recent = true }
    eks-pod-identity-agent = { most_recent = true } # lets pods use IAM roles (phase 3)
  }

  # Worker nodes: a managed group of EC2 instances that AWS patches and replaces.
  eks_managed_node_groups = {
    general = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = var.node_instance_types
      subnet_ids     = local.app_subnet_ids

      min_size     = 1
      desired_size = 2
      max_size     = 3

      labels = {
        workload = "general"
      }
    }
  }
}
