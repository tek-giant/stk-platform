# The role a CI pipeline assumes to run "terraform plan". It can read what Terraform compares
# against, take the state lock, and nothing else: it cannot apply anything.

data "aws_iam_policy_document" "plan_trust" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = [local.sso_admin_role_arn]
    }
  }
}

resource "aws_iam_role" "plan" {
  name                 = "stk-ci-plan"
  assume_role_policy   = data.aws_iam_policy_document.plan_trust.json
  max_session_duration = 3600
}

resource "aws_iam_role_policy_attachment" "plan_read_only" {
  role       = aws_iam_role.plan.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

data "aws_iam_policy_document" "plan_state" {
  statement {
    sid       = "ReadTheStateBucket"
    actions   = ["s3:GetObject", "s3:ListBucket", "s3:GetBucketLocation"]
    resources = ["arn:aws:s3:::stk-tfstate-${data.aws_caller_identity.current.account_id}", "arn:aws:s3:::stk-tfstate-${data.aws_caller_identity.current.account_id}/*"]
  }

  statement {
    sid       = "TakeTheStateLock"
    actions   = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:DeleteItem", "dynamodb:DescribeTable"]
    resources = ["arn:aws:dynamodb:eu-west-2:${data.aws_caller_identity.current.account_id}:table/stk-tf-locks"]
  }

  statement {
    sid       = "DecryptTheState"
    actions   = ["kms:Decrypt", "kms:DescribeKey"]
    resources = [aws_kms_key.project.arn]
  }
}

resource "aws_iam_role_policy" "plan_state" {
  name   = "read-state-and-take-the-lock"
  role   = aws_iam_role.plan.id
  policy = data.aws_iam_policy_document.plan_state.json
}

output "plan_role_arn" {
  value = aws_iam_role.plan.arn
}
