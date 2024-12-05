resource "aws_s3_bucket" "file_storage_bucket" {
  bucket = "${var.project_name}-user-files-${var.environment}"
  force_destroy = true
}

resource "aws_s3_bucket_cors_configuration" "file_storage_bucket_cors" {
  bucket = aws_s3_bucket.file_storage_bucket.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST", "DELETE"]
    allowed_origins = ["*"]
    max_age_seconds = 3000
  }
}
