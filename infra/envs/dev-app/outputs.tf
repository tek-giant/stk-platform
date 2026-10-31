output "alb_dns_name" {
  value = aws_lb.internal.dns_name
}

output "cluster_name" {
  value = aws_ecs_cluster.main.name
}

output "service_name" {
  value = aws_ecs_service.stock_api.name
}
