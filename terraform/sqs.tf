###############################################################################
# Applicant Viewing Processor — SQS Queue + Dead-Letter Queue
###############################################################################

resource "aws_sqs_queue" "applicant_viewing_processor_dlq" {
  name = "applicant-viewing-processor-dlq"
  tags = var.tags
}

resource "aws_sqs_queue" "applicant_viewing_processor" {
  name = "applicant-viewing-processor"

  visibility_timeout_seconds = 60 # Must be >= Lambda timeout (30s), recommended 2x

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.applicant_viewing_processor_dlq.arn
    maxReceiveCount     = 3
  })

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "applicant_viewing_processor_dlq" {
  alarm_name          = "applicant-viewing-processor-dlq-not-empty"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Messages in the applicant-viewing-processor DLQ — requires investigation"

  dimensions = {
    QueueName = aws_sqs_queue.applicant_viewing_processor_dlq.name
  }

  tags = var.tags
}
