#backend configuration
terraform {
  backend "s3" {
  }
}

#create SQS queue
resource "aws_sqs_queue" "sqs_queue" {
  name                      = "${var.name}-${var.env}-queue"
  delay_seconds             = var.delay_seconds
  max_message_size          = var.message_size
  message_retention_seconds = var.retention_seconds
  receive_wait_time_seconds = var.receive_wait_time
  redrive_policy = jsonencode({
    deadLetterTargetArn = var.deadletter_sqs_arn
    maxReceiveCount     = var.deadletter_receive_count
  })

  tags = {
    Name = var.name
    Environment = var.env
  }
}