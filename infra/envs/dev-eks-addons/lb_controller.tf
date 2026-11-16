# AWS Load Balancer Controller
# Watches for Ingress objects in the cluster and creates a real AWS ALB for each.

# 1. An IAM role the controller's pod can use (Pod Identity).
#    The module attaches AWS's published policy for the controller and links
#    the role to the "aws-load-balancer-controller" service account.
module "aws_lb_controller_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.4"

  name = "stk-dev-aws-lbc"

  attach_aws_lb_controller_policy = true

  associations = {
    controller = {
      cluster_name    = local.cluster_name
      namespace       = "kube-system"
      service_account = "aws-load-balancer-controller"
    }
  }
}

# 2. The controller itself, installed with its official Helm chart.
resource "helm_release" "aws_lb_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = var.lb_controller_chart_version
  namespace  = "kube-system"

  set {
    name  = "clusterName"
    value = local.cluster_name
  }

  set {
    name  = "region"
    value = "eu-west-2"
  }

  set {
    name  = "vpcId"
    value = data.aws_eks_cluster.this.vpc_config[0].vpc_id
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  # Two copies, one per node, so it survives a node being replaced.
  set {
    name  = "replicaCount"
    value = "2"
  }

  # The IAM role must exist before the controller starts asking AWS for things.
  depends_on = [module.aws_lb_controller_pod_identity]
}
