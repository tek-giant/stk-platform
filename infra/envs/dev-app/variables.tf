variable "image_tag" {
  description = "Version of the stock-api image to run"
  type        = string
  default     = "0.1.0"
}

variable "desired_count" {
  description = "How many copies of the app to run"
  type        = number
  default     = 2
}
