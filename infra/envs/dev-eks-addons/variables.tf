variable "lb_controller_chart_version" {
  description = "Helm chart version of the AWS Load Balancer Controller. Check the latest with: helm search repo eks/aws-load-balancer-controller"
  type        = string
  default     = "1.13.0"
}
