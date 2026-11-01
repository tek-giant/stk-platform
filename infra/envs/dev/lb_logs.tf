data "aws_elb_service_account" "main" {}

resource "aws_s3_bucket" "lb_logs" {
  bucket = "stk-lb-logs-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket_public_access_block" "lb_logs" {
  bucket                  = aws_s3_bucket.lb_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "lb_logs" {
  bucket = aws_s3_bucket.lb_logs.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "lb_logs" {
  bucket = aws_s3_bucket.lb_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "lb_logs" {
  bucket = aws_s3_bucket.lb_logs.id
  rule {
    id     = "expire-old-logs"
    status = "Enabled"
    filter {}
    expiration {
      days = 90
    }
    noncurrent_version_expiration {
      noncurrent_days = 7
    }
  }
}

data "aws_iam_policy_document" "lb_logs" {
  statement {
    sid       = "AllowElbToWriteLogs"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.lb_logs.arn}/*"]
    principals {
      type        = "AWS"
      identifiers = [data.aws_elb_service_account.main.arn]
    }
  }
  statement {
    sid       = "DenyInsecureTransport"
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = [aws_s3_bucket.lb_logs.arn, "${aws_s3_bucket.lb_logs.arn}/*"]
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

resource "aws_s3_bucket_policy" "lb_logs" {
  bucket     = aws_s3_bucket.lb_logs.id
  policy     = data.aws_iam_policy_document.lb_logs.json
  depends_on = [aws_s3_bucket_public_access_block.lb_logs]
}

output "lb_logs_bucket" {
  value = aws_s3_bucket.lb_logs.id
}