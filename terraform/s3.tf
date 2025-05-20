resource "aws_s3_bucket" "data_bucket" {
  bucket = "myapp-bucket-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name        = "DataBucket"
    Environment = "dev"
  }
}

resource "aws_s3_bucket_public_access_block" "block" {
  bucket                  = aws_s3_bucket.data_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
