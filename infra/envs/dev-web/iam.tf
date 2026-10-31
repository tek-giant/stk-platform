data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "web" {
  name               = "${local.name}-web-instance"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
}

# A shell through Systems Manager, so port 22 never needs opening
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.web.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy_document" "ecr_pull" {
  statement {
    sid       = "LogIn"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid = "PullTheWebImageOnly"
    actions = [
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchCheckLayerAvailability",
    ]
    resources = [data.aws_ecr_repository.web.arn]
  }
}

resource "aws_iam_role_policy" "ecr_pull" {
  name   = "pull-web-image"
  role   = aws_iam_role.web.id
  policy = data.aws_iam_policy_document.ecr_pull.json
}

resource "aws_iam_instance_profile" "web" {
  name = "${local.name}-web-instance"
  role = aws_iam_role.web.name
}
