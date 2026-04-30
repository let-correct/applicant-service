###############################################################################
# Applicant Viewing Processor — ECR Repository
###############################################################################

resource "aws_ecr_repository" "applicant_viewing_processor" {
  name = "applicant_viewing_processor_ecr"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = var.tags
}

resource "aws_ecr_lifecycle_policy" "applicant_viewing_processor" {
  repository = aws_ecr_repository.applicant_viewing_processor.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 1 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 1
      }
      action = { type = "expire" }
    }]
  })
}
