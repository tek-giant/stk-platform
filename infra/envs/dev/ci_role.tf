# The SSO administrator role allowed to assume the CI roles. It is pinned, not looked up,
# so a plan gives the same answer on the laptop and in Jenkins.
locals {
  sso_admin_role_arn = "arn:aws:iam::743978812281:role/aws-reserved/sso.amazonaws.com/eu-west-2/AWSReservedSSO_AdministratorAccess_6c92655dbb526cf2"
}

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
      identifiers = [local.sso_admin_role_arn]
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
