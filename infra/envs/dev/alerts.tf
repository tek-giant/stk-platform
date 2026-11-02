# The alert address lives in Parameter Store (SecureString, project key), never in the repo.
data "aws_ssm_parameter" "alert_email" {
  name            = "/stk/dev/alert_email"
  with_decryption = true
}

resource "aws_sns_topic" "alerts" {
  name              = "stk-dev-alerts"
  kms_master_key_id = aws_kms_key.project.arn
}

data "aws_iam_policy_document" "alerts_publish" {
  statement {
    sid       = "AllowCloudWatchAlarmsToPublish"
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.alerts.arn]

    principals {
      type        = "Service"
      identifiers = ["cloudwatch.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_sns_topic_policy" "alerts" {
  arn    = aws_sns_topic.alerts.arn
  policy = data.aws_iam_policy_document.alerts_publish.json
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = data.aws_ssm_parameter.alert_email.value
}

output "alerts_topic_arn" {
  value = aws_sns_topic.alerts.arn
}
