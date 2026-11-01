# The role a CI pipeline assumes. It can push to the two registries and read their scan
# results, and it cannot do anything else. There is no stored key: only the identity below
# can assume it, and each session lasts at most one hour.

data "aws_iam_session_context" "me" {
  arn = data.aws_caller_identity.current.arn
}

data "aws_iam_policy_document" "ci_trust" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = [data.aws_iam_session_context.me.issuer_arn]
    }
  }
}

resource "aws_iam_role" "ci" {
  name                 = "stk-ci-pipeline"
  assume_role_policy   = data.aws_iam_policy_document.ci_trust.json
  max_session_duration = 3600
}

data "aws_iam_policy_document" "ci_registries" {
  statement {
    sid       = "RegistryLogin"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid = "PushAndReadTheTwoRepositories"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeImages",
      "ecr:DescribeImageScanFindings",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
    ]
    resources = [
      aws_ecr_repository.stock_api.arn,
      aws_ecr_repository.web.arn,
    ]
  }
}

resource "aws_iam_role_policy" "ci_registries" {
  name   = "push-to-the-two-registries"
  role   = aws_iam_role.ci.id
  policy = data.aws_iam_policy_document.ci_registries.json
}

output "ci_role_arn" {
  value = aws_iam_role.ci.arn
}
