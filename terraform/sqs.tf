resource "aws_sqs_queue" "messages" {
  name                       = "myappqueue"
  message_retention_seconds  = 86400
  visibility_timeout_seconds = 30

  tags = {
    Environment = "dev"
    Name        = "MyAppSQS"
  }
}
