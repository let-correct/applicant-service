###############################################################################
# Data sources — cross-service references to agent-service resources
###############################################################################

# The oauth-tokens DynamoDB table is owned by agent-service.
# The applicant-viewing-processor reads Arthur tokens directly from it.
data "aws_dynamodb_table" "oauth_tokens" {
  name = "oauth-tokens"
}

# The KMS key used by agent-service to encrypt tokens at rest.
data "aws_kms_alias" "oauth_tokens" {
  name = "alias/auth-lambda-oauth-tokens"
}

###############################################################################
# Applicant Viewing Processor Lambda
###############################################################################

resource "aws_lambda_function" "applicant_viewing_processor" {
  function_name = "applicant-viewing-processor"
  role          = aws_iam_role.applicant_viewing_processor.arn

  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.applicant_viewing_processor.repository_url}:latest"
  architectures = ["arm64"]

  memory_size = 128
  timeout     = 30

  environment {
    variables = {
      LOG_LEVEL        = var.log_level
      TOKEN_TABLE_NAME = data.aws_dynamodb_table.oauth_tokens.name
      KMS_KEY_ARN      = data.aws_kms_alias.oauth_tokens.target_key_arn
    }
  }

  logging_config {
    log_format = "JSON"
    log_group  = aws_cloudwatch_log_group.applicant_viewing_processor.name
  }

  tags = var.tags

  depends_on = [
    aws_iam_role_policy_attachment.applicant_viewing_processor_basic_execution,
    aws_cloudwatch_log_group.applicant_viewing_processor,
  ]
}

resource "aws_lambda_event_source_mapping" "applicant_viewing_processor_sqs" {
  event_source_arn        = aws_sqs_queue.applicant_viewing_processor.arn
  function_name           = aws_lambda_function.applicant_viewing_processor.arn
  batch_size              = 10
  function_response_types = ["ReportBatchItemFailures"]
}

###############################################################################
# IAM
###############################################################################

data "aws_iam_policy_document" "applicant_viewing_processor_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "applicant_viewing_processor" {
  name               = "applicant-viewing-processor-execution-role"
  assume_role_policy = data.aws_iam_policy_document.applicant_viewing_processor_assume_role.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "applicant_viewing_processor_basic_execution" {
  role       = aws_iam_role.applicant_viewing_processor.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "applicant_viewing_processor_permissions" {
  name = "applicant-viewing-processor-permissions"
  role = aws_iam_role.applicant_viewing_processor.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"]
        Resource = aws_sqs_queue.applicant_viewing_processor.arn
      },
      {
        Effect   = "Allow"
        Action   = ["dynamodb:GetItem"]
        Resource = data.aws_dynamodb_table.oauth_tokens.arn
      },
      {
        Effect   = "Allow"
        Action   = ["kms:Decrypt"]
        Resource = data.aws_kms_alias.oauth_tokens.target_key_arn
      },
    ]
  })
}

###############################################################################
# CloudWatch Log Group
###############################################################################

resource "aws_cloudwatch_log_group" "applicant_viewing_processor" {
  name              = "/aws/lambda/applicant_viewing_processor"
  retention_in_days = 30
  tags              = var.tags
}
