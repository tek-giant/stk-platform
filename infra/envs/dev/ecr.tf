resource "aws_ecr_repository" "stock_api" {
  name                 = "stk/stock-api"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = aws_kms_key.project.arn
  }
}

resource "aws_ecr_lifecycle_policy" "stock_api" {
  repository = aws_ecr_repository.stock_api.name

  policy = jsonencode({
    rules = [
      {
        # Pipeline build images look like "<commit>-<build number>": keep the newest 10.
        # Release tags such as 0.1.0 have no hyphen, so this rule never touches them.
        rulePriority = 1
        description  = "Keep only the last 10 build images"
        selection = {
          tagStatus      = "tagged"
          tagPatternList = ["*-*"]
          countType      = "imageCountMoreThan"
          countNumber    = 10
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 2
        description  = "Expire untagged images after 14 days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 14
        }
        action = { type = "expire" }
      }
    ]
  })
}

output "ecr_repository_url" {
  value = aws_ecr_repository.stock_api.repository_url
}
