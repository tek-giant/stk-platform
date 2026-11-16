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

  # Name the cluster admin explicitly: your SSO admin role.
  # (Not "whoever runs terraform", which changes depending on which login you use.)
  enable_cluster_creator_admin_permissions = false

  access_entries = {
    sso_admin = {
      principal_arn = one(data.aws_iam_roles.sso_admin.arns)

      policy_associations = {
        admin = {
          policy_arn   = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = { type = "cluster" }
        }
      }
    }
  }

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
    metrics-server         = { most_recent = true } # CPU/memory usage, needed for autoscaling
  }

    # Let the control plane reach metrics-server on the nodes (EKS add-on uses port 10251).
  node_security_group_additional_rules = {
    ingress_cluster_metrics_server = {
      description                   = "Control plane to metrics-server"
      protocol                      = "tcp"
      from_port                     = 10251
      to_port                       = 10251
      type                          = "ingress"
      source_cluster_security_group = true
    }
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

# Find your SSO admin role's exact ARN, so it isn't hard-coded.
data "aws_iam_roles" "sso_admin" {
  name_regex  = "AWSReservedSSO_AdministratorAccess_.*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}