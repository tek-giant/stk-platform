locals {
  alerts_topic_arn = data.terraform_remote_state.network.outputs.alerts_topic_arn
}

resource "aws_cloudwatch_metric_alarm" "app_alb_5xx" {
  alarm_name          = "${local.name}-app-alb-5xx"
  alarm_description   = "The internal load balancer itself returned 5xx errors"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "HTTPCode_ELB_5XX_Count"
  dimensions          = { LoadBalancer = aws_lb.internal.arn_suffix }
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 5
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [local.alerts_topic_arn]
  ok_actions          = [local.alerts_topic_arn]
}

resource "aws_cloudwatch_metric_alarm" "app_target_5xx" {
  alarm_name          = "${local.name}-app-target-5xx"
  alarm_description   = "The API containers returned 5xx errors"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "HTTPCode_Target_5XX_Count"
  dimensions          = { LoadBalancer = aws_lb.internal.arn_suffix, TargetGroup = aws_lb_target_group.app.arn_suffix }
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 5
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [local.alerts_topic_arn]
  ok_actions          = [local.alerts_topic_arn]
}

resource "aws_cloudwatch_metric_alarm" "app_targets_unhealthy" {
  alarm_name          = "${local.name}-app-targets-unhealthy"
  alarm_description   = "At least one API container has failed its health check for 3 minutes"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "UnHealthyHostCount"
  dimensions          = { LoadBalancer = aws_lb.internal.arn_suffix, TargetGroup = aws_lb_target_group.app.arn_suffix }
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 3
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [local.alerts_topic_arn]
  ok_actions          = [local.alerts_topic_arn]
}
