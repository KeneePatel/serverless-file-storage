# Archive for List Files Lambda
data "archive_file" "list_files" {
  type        = "zip"
  source_dir = "${path.module}/lambda/list_files"
  output_path = "${path.module}/lambda/list_files.zip"
}

# Archive for Validate File Lambda
data "archive_file" "validate_file" {
  type        = "zip"
  source_file = "${path.module}/lambda/validate_file/index.js"
  output_path = "${path.module}/lambda/validate_file.zip"
}

# Archive for Upload File Lambda
data "archive_file" "upload_file" {
  type        = "zip"
  source_dir = "${path.module}/lambda/upload_file"
  output_path = "${path.module}/lambda/upload_file.zip"
}

# Archive for Download File Lambda
data "archive_file" "download_file" {
  type        = "zip"
  source_dir = "${path.module}/lambda/download_file"
  output_path = "${path.module}/lambda/download_file.zip"
}

# Archive for Update File Status Lambda
data "archive_file" "update_file_status" {
  type        = "zip"
  source_dir = "${path.module}/lambda/update_file_status"
  output_path = "${path.module}/lambda/update_file_status.zip"
}

# Archive for Get Execution Result Lambda
data "archive_file" "get_execution_result" {
  type        = "zip"
  source_dir = "${path.module}/lambda/get_execution_result"
  output_path = "${path.module}/lambda/get_execution_result.zip"
}

# List Files Lambda
resource "aws_lambda_function" "list_files" {
  filename         = data.archive_file.list_files.output_path
  source_code_hash = data.archive_file.list_files.output_base64sha256
  function_name    = "${var.project_name}-list-files"
  role            = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/LabRole"
  handler         = "index.handler"
  runtime         = "nodejs22.x"
  timeout         = 30

  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.file_storage_bucket.id
      TABLE_NAME  = aws_dynamodb_table.file_metadata.name
    }
  }
}

# Validate File Lambda
resource "aws_lambda_function" "validate_file" {
  filename         = data.archive_file.validate_file.output_path
  source_code_hash = data.archive_file.validate_file.output_base64sha256
  function_name    = "${var.project_name}-validate-file"
  role            = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/LabRole"
  handler         = "index.handler"
  runtime         = "nodejs22.x"
  timeout         = 30

  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.file_storage_bucket.id
      TABLE_NAME  = aws_dynamodb_table.file_metadata.name
    }
  }
}

# Upload File Lambda
resource "aws_lambda_function" "upload_file" {
  filename         = data.archive_file.upload_file.output_path
  source_code_hash = data.archive_file.upload_file.output_base64sha256
  function_name    = "${var.project_name}-upload-file"
  role            = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/LabRole"
  handler         = "index.handler"
  runtime         = "nodejs22.x"
  timeout         = 30

  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.file_storage_bucket.id
      TABLE_NAME  = aws_dynamodb_table.file_metadata.name
    }
  }
}

# Download File Lambda
resource "aws_lambda_function" "download_file" {
  filename         = data.archive_file.download_file.output_path
  source_code_hash = data.archive_file.download_file.output_base64sha256
  function_name    = "${var.project_name}-download-file"
  role            = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/LabRole"
  handler         = "index.handler"
  runtime         = "nodejs22.x"
  timeout         = 30

  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.file_storage_bucket.id
      TABLE_NAME  = aws_dynamodb_table.file_metadata.name
    }
  }
}

# Status update Lambda
resource "aws_lambda_function" "update_file_status" {
  filename         = data.archive_file.update_file_status.output_path
  source_code_hash = data.archive_file.update_file_status.output_base64sha256
  function_name    = "${var.project_name}-update-file-status"
  role            = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/LabRole"
  handler         = "index.handler"
  runtime         = "nodejs22.x"
  timeout         = 30

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.file_metadata.name
    }
  }
}

# Lambda permission for S3
resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.update_file_status.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.file_storage_bucket.arn
}

# S3 bucket notification
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.file_storage_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.update_file_status.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_s3]
}

# Get Execution Result Lambda
resource "aws_lambda_function" "get_execution_result" {
  filename         = data.archive_file.get_execution_result.output_path
  source_code_hash = data.archive_file.get_execution_result.output_base64sha256
  function_name    = "${var.project_name}-get-execution-result"
  role            = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/LabRole"
  handler         = "index.handler"
  runtime         = "nodejs22.x"
  timeout         = 30
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}
