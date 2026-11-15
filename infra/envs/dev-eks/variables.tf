variable "cluster_version" {
  description = "Kubernetes version. Use one in AWS standard support: extended support costs much more."
  type        = string
  default     = "1.37"
}

variable "admin_cidrs" {
  description = "IP ranges allowed to reach the cluster API (kubectl). Your own IP as x.x.x.x/32."
  type        = list(string)

  validation {
    condition     = length(var.admin_cidrs) > 0 && !contains(var.admin_cidrs, "0.0.0.0/0")
    error_message = "List at least one IP range, and not 0.0.0.0/0."
  }
}

variable "node_instance_types" {
  description = "EC2 instance types for the worker nodes."
  type        = list(string)
  default     = ["t3.medium"]
}
