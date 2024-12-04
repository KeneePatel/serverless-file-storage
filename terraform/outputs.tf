output "cognito_user_pool_id" {
  value = aws_cognito_user_pool.file_storage_pool.id
}

output "s3_bucket_name" {
  value = aws_s3_bucket.file_storage_bucket.id
}
