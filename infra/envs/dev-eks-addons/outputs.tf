output "lb_controller_role_arn" {
  description = "IAM role the Load Balancer Controller uses through Pod Identity"
  value       = module.aws_lb_controller_pod_identity.iam_role_arn
}
