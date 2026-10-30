data "aws_caller_identity" "current" {}

# Key policy: only the account itself, so IAM policies decide who may use the key.
# Services such as RDS, CloudTrail or CloudWatch will be added to it when they need it.
data "aws_iam_policy_document" "project_key" {
  statement {
    sid       = "EnableIamPolicies"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }
}

resource "aws_kms_key" "project" {
  description             = "Encrypts Stock Platform dev data (database, disks, logs)"
  enable_key_rotation     = true
  deletion_window_in_days = 7
  policy                  = data.aws_iam_policy_document.project_key.json
}

resource "aws_kms_alias" "project" {
  name          = "alias/stk-dev"
  target_key_id = aws_kms_key.project.key_id
}

output "kms_key_arn" {
  value = aws_kms_key.project.arn
}
