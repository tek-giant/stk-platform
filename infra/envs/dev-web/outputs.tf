output "public_alb_dns_name" {
  description = "The address of the website while the web tier is up"
  value       = aws_lb.public.dns_name
}

output "asg_name" {
  value = aws_autoscaling_group.web.name
}
