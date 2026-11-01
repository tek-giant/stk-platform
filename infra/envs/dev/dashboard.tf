resource "aws_cloudwatch_dashboard" "stack" {
  dashboard_name = "stk-dev-stack"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "text"
        x      = 0
        y      = 0
        width  = 24
        height = 2
        properties = {
          markdown = "# Stock Platform (dev)\nWeb layer on the left, app layer in the middle, database on the right. A panel is empty while its layer is destroyed. Alarm emails go to the stk-dev-alerts topic."
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 2
        width  = 8
        height = 6
        properties = {
          title  = "Public load balancer: requests and 5xx"
          region = "eu-west-2"
          view   = "timeSeries"
          period = 300
          metrics = [
            [{ expression = "SEARCH('{AWS/ApplicationELB,LoadBalancer} MetricName=\"RequestCount\" LoadBalancer=\"app/stk-dev-public-alb*\"', 'Sum', 300)", id = "web_req" }],
            [{ expression = "SEARCH('{AWS/ApplicationELB,LoadBalancer} MetricName=\"HTTPCode_ELB_5XX_Count\" LoadBalancer=\"app/stk-dev-public-alb*\"', 'Sum', 300)", id = "web_5xx" }]
          ]
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 2
        width  = 8
        height = 6
        properties = {
          title  = "Internal load balancer: requests and 5xx"
          region = "eu-west-2"
          view   = "timeSeries"
          period = 300
          metrics = [
            [{ expression = "SEARCH('{AWS/ApplicationELB,LoadBalancer} MetricName=\"RequestCount\" LoadBalancer=\"app/stk-dev-alb*\"', 'Sum', 300)", id = "app_req" }],
            [{ expression = "SEARCH('{AWS/ApplicationELB,LoadBalancer} MetricName=\"HTTPCode_ELB_5XX_Count\" LoadBalancer=\"app/stk-dev-alb*\"', 'Sum', 300)", id = "app_5xx" }]
          ]
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 2
        width  = 8
        height = 6
        properties = {
          title   = "Database: CPU"
          region  = "eu-west-2"
          view    = "timeSeries"
          stat    = "Average"
          period  = 300
          metrics = [["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", "stk-dev-db"]]
        }
      },
      {
        type   = "alarm"
        x      = 0
        y      = 8
        width  = 24
        height = 4
        properties = {
          title = "Alarms"
          alarms = [
            "arn:aws:cloudwatch:eu-west-2:${data.aws_caller_identity.current.account_id}:alarm:stk-dev-web-alb-5xx",
            "arn:aws:cloudwatch:eu-west-2:${data.aws_caller_identity.current.account_id}:alarm:stk-dev-web-targets-unhealthy",
            "arn:aws:cloudwatch:eu-west-2:${data.aws_caller_identity.current.account_id}:alarm:stk-dev-app-alb-5xx",
            "arn:aws:cloudwatch:eu-west-2:${data.aws_caller_identity.current.account_id}:alarm:stk-dev-app-target-5xx",
            "arn:aws:cloudwatch:eu-west-2:${data.aws_caller_identity.current.account_id}:alarm:stk-dev-app-targets-unhealthy",
            "arn:aws:cloudwatch:eu-west-2:${data.aws_caller_identity.current.account_id}:alarm:stk-dev-db-cpu-high",
            "arn:aws:cloudwatch:eu-west-2:${data.aws_caller_identity.current.account_id}:alarm:stk-dev-db-storage-low"
          ]
        }
      }
    ]
  })
}

output "dashboard_name" {
  value = aws_cloudwatch_dashboard.stack.dashboard_name
}