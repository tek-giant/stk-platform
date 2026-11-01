data "aws_s3_bucket" "ansible_transfer" {
  bucket = "stk-ansible-transfer-${data.aws_caller_identity.current.account_id}"
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "ansible_transfer" {
  statement {
    sid       = "AnsibleTransferObjects"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["${data.aws_s3_bucket.ansible_transfer.arn}/*"]
  }

  statement {
    sid       = "AnsibleTransferList"
    actions   = ["s3:ListBucket", "s3:GetBucketLocation"]
    resources = [data.aws_s3_bucket.ansible_transfer.arn]
  }
}

resource "aws_iam_role_policy" "ansible_transfer" {
  name   = "ansible-transfer-bucket"
  role   = aws_iam_role.web.id
  policy = data.aws_iam_policy_document.ansible_transfer.json
}
