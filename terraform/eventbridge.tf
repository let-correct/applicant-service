###############################################################################
# Data source — the shared let-correct event bus owned by agent-service
###############################################################################

data "aws_cloudwatch_event_bus" "let_correct" {
  name = "let-correct"
}

###############################################################################
# EventBridge Rule — filter ViewingScheduled / ViewingCancelled events
# from viewing-service into the applicant-viewing-processor SQS queue.
###############################################################################

resource "aws_cloudwatch_event_rule" "viewings" {
  name           = "applicant-service-viewings"
  description    = "Routes viewing events from viewing-service to applicant-service"
  event_bus_name = data.aws_cloudwatch_event_bus.let_correct.name

  event_pattern = jsonencode({
    source      = ["viewing-service"]
    detail-type = ["ViewingScheduled", "ViewingCancelled"]
  })

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "viewings_sqs" {
  rule           = aws_cloudwatch_event_rule.viewings.name
  event_bus_name = data.aws_cloudwatch_event_bus.let_correct.name
  arn            = aws_sqs_queue.applicant_viewing_processor.arn
}

resource "aws_sqs_queue_policy" "applicant_viewing_processor_eventbridge" {
  queue_url = aws_sqs_queue.applicant_viewing_processor.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "events.amazonaws.com" }
        Action    = "sqs:SendMessage"
        Resource  = aws_sqs_queue.applicant_viewing_processor.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_cloudwatch_event_rule.viewings.arn
          }
        }
      }
    ]
  })
}
