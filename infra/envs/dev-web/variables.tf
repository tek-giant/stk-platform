variable "image_tag" {
  description = "Version of the web image to run"
  type        = string
  default     = "0.1.1"
}

variable "desired_count" {
  description = "How many web servers to run"
  type        = number
  default     = 2
}

variable "instance_type" {
  description = "EC2 size, x86_64 to match the linux/amd64 image"
  type        = string
  default     = "t3.micro"
}
