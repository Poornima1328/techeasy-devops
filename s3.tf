resource "aws_s3_bucket" "logs" {
  bucket = var.bucket_name
  force_destroy = true
}

resource "aws_s3_bucket_lifecycle_configuration" "logs_lifecycle" {
  bucket = aws_s3_bucket.logs.id
  rule {
    id     = "delete_old_logs"
    status = "Enabled"
    filter { prefix = "app/logs/" }
    expiration { days = 7 }
  }
}
