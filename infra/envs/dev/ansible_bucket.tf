# Scratch space for Ansible's SSM connection: files pass through here on their way to the servers.
resource "aws_s3_bucket" "ansible_transfer" {
  bucket = "stk-ansible-transfer-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket_public_access_block" "ansible_transfer" {
  bucket                  = aws_s3_bucket.ansible_transfer.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "ansible_transfer" {
  bucket = aws_s3_bucket.ansible_transfer.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "ansible_transfer" {
  bucket = aws_s3_bucket.ansible_transfer.id

  rule {
    id     = "expire-transfer-files"
    status = "Enabled"

    filter {}

    expiration {
      days = 1
    }
  }
}

data "aws_iam_policy_document" "ansible_transfer_tls" {
  statement {
    sid       = "DenyInsecureTransport"
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = [aws_s3_bucket.ansible_transfer.arn, "${aws_s3_bucket.ansible_transfer.arn}/*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "ansible_transfer" {
  bucket     = aws_s3_bucket.ansible_transfer.id
  policy     = data.aws_iam_policy_document.ansible_transfer_tls.json
  depends_on = [aws_s3_bucket_public_access_block.ansible_transfer]
}

output "ansible_transfer_bucket" {
  value = aws_s3_bucket.ansible_transfer.id
}
