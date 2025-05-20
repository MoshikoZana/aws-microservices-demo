output "alb_dns" {
  value = aws_lb.app_alb.dns_name
}

output "s3_bucket" {
  value = aws_s3_bucket.data_bucket.bucket
}

output "sqs_queue_url" {
  value = aws_sqs_queue.messages.id
}
