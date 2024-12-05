# Outputs for cognito integration
output "cognito_user_pool_id" {
  value = aws_cognito_user_pool.file_storage_pool.id
}

output "cognito_user_pool_client_id" {
  value = aws_cognito_user_pool_client.file_storage_client.id
}


# Outputs for S3 Bucket details
output "s3_bucket_name" {
  value = aws_s3_bucket.file_storage_bucket.id
}

output "s3_bucket_arn" {
  value = aws_s3_bucket.file_storage_bucket.arn
}


# Outputs for DynamoDB table
output "dynamodb_table_name" {
  value = aws_dynamodb_table.file_metadata.name
}


# Outputs for Step Function
output "step_function_arn" {
  value = aws_sfn_state_machine.upload_workflow.arn
  description = "ARN of the Step Function state machine"
}

# Outputs for API Gateway
output "api_url" {
  value = "${aws_api_gateway_stage.api_stage.invoke_url}/files"
}

# Outputs for frontend environment variables
output "frontend_env" {
  value = {
    NEXT_PUBLIC_REGION        = var.aws_region
    NEXT_PUBLIC_USER_POOL_ID  = aws_cognito_user_pool.file_storage_pool.id
    NEXT_PUBLIC_USER_POOL_CLIENT_ID = aws_cognito_user_pool_client.file_storage_client.id
    NEXT_PUBLIC_API_URL       = "${aws_api_gateway_stage.api_stage.invoke_url}"
  }
  description = "Environment variables for frontend application"
}
