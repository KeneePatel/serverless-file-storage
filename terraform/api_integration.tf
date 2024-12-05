# API Gateway
resource "aws_api_gateway_rest_api" "file_storage_api" {
  name = "${var.project_name}-api"
}

# Enable CORS for the API
resource "aws_api_gateway_resource" "cors_preflight" {
  rest_api_id = aws_api_gateway_rest_api.file_storage_api.id
  parent_id   = aws_api_gateway_rest_api.file_storage_api.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "cors_preflight" {
  rest_api_id   = aws_api_gateway_rest_api.file_storage_api.id
  resource_id   = aws_api_gateway_resource.cors_preflight.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "cors_preflight" {
  rest_api_id = aws_api_gateway_rest_api.file_storage_api.id
  resource_id = aws_api_gateway_resource.cors_preflight.id
  http_method = aws_api_gateway_method.cors_preflight.http_method
  type        = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "cors_preflight" {
  rest_api_id = aws_api_gateway_rest_api.file_storage_api.id
  resource_id = aws_api_gateway_resource.cors_preflight.id
  http_method = aws_api_gateway_method.cors_preflight.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "cors_preflight" {
  rest_api_id = aws_api_gateway_rest_api.file_storage_api.id
  resource_id = aws_api_gateway_resource.cors_preflight.id
  http_method = aws_api_gateway_method.cors_preflight.http_method
  status_code = aws_api_gateway_method_response.cors_preflight.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

# Resource for /files
resource "aws_api_gateway_resource" "files" {
  rest_api_id = aws_api_gateway_rest_api.file_storage_api.id
  parent_id   = aws_api_gateway_rest_api.file_storage_api.root_resource_id
  path_part   = "files"
}

# LIST files method
resource "aws_api_gateway_method" "list_files" {
  rest_api_id   = aws_api_gateway_rest_api.file_storage_api.id
  resource_id   = aws_api_gateway_resource.files.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_integration" "list_files" {
  rest_api_id = aws_api_gateway_rest_api.file_storage_api.id
  resource_id = aws_api_gateway_resource.files.id
  http_method = aws_api_gateway_method.list_files.http_method
  type        = "AWS_PROXY"
  integration_http_method = "POST"
  uri         = aws_lambda_function.list_files.invoke_arn
}

# UPLOAD file method (starts step function)
resource "aws_api_gateway_method" "upload_file" {
  rest_api_id   = aws_api_gateway_rest_api.file_storage_api.id
  resource_id   = aws_api_gateway_resource.files.id
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

# Integration
resource "aws_api_gateway_integration" "upload_file" {
  rest_api_id = aws_api_gateway_rest_api.file_storage_api.id
  resource_id = aws_api_gateway_resource.files.id
  http_method = aws_api_gateway_method.upload_file.http_method
  type        = "AWS"
  integration_http_method = "POST"
  uri         = "arn:aws:apigateway:${var.aws_region}:states:action/StartExecution"
  credentials = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/LabRole"
  
  passthrough_behavior = "WHEN_NO_TEMPLATES"

  request_templates = {
    "application/json" = <<EOF
#set($inputRoot = $input.path('$'))
{
    "input": "{\"fileName\": \"$inputRoot.fileName\", \"fileType\": \"$inputRoot.fileType\", \"fileSize\": $inputRoot.fileSize, \"userId\": \"$context.authorizer.claims.sub\"}",
    "stateMachineArn": "${aws_sfn_state_machine.upload_workflow.arn}"
}
EOF
  }
}

# Success response
resource "aws_api_gateway_integration_response" "upload_file_success" {
  rest_api_id = aws_api_gateway_rest_api.file_storage_api.id
  resource_id = aws_api_gateway_resource.files.id
  http_method = aws_api_gateway_method.upload_file.http_method
  status_code = aws_api_gateway_method_response.upload_file_response_200.status_code
  selection_pattern = "2\\d{2}"

  response_templates = {
    "application/json" = <<EOF
#set($context.responseOverride.header.Content-Type = 'application/json')
{
    "status": "success",
    "executionArn": $input.json('$.executionArn'),
}
EOF
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,OPTIONS'"
  }

  depends_on = [
    aws_api_gateway_integration.upload_file
  ]
}

# Error response
resource "aws_api_gateway_integration_response" "upload_file_error" {
  rest_api_id = aws_api_gateway_rest_api.file_storage_api.id
  resource_id = aws_api_gateway_resource.files.id
  http_method = aws_api_gateway_method.upload_file.http_method
  status_code = aws_api_gateway_method_response.upload_file_response_400.status_code
  selection_pattern = "4\\d{2}"  # Match 4XX responses

  response_templates = {
    "application/json" = <<EOF
#set($inputRoot = $input.path('$'))
{
    "status": "error",
    "message": $input.json('$.message')
}
EOF
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,OPTIONS'"
  }

  depends_on = [
    aws_api_gateway_integration.upload_file
  ]
}

# Success Method Response
resource "aws_api_gateway_method_response" "upload_file_response_200" {
  rest_api_id = aws_api_gateway_rest_api.file_storage_api.id
  resource_id = aws_api_gateway_resource.files.id
  http_method = aws_api_gateway_method.upload_file.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
  }
}

# Error Method Response
resource "aws_api_gateway_method_response" "upload_file_response_400" {
  rest_api_id = aws_api_gateway_rest_api.file_storage_api.id
  resource_id = aws_api_gateway_resource.files.id
  http_method = aws_api_gateway_method.upload_file.http_method
  status_code = "400"

  response_models = {
    "application/json" = "Error"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
  }
}

# Resource for /executions/{executionArn}
resource "aws_api_gateway_resource" "execution" {
  rest_api_id = aws_api_gateway_rest_api.file_storage_api.id
  parent_id   = aws_api_gateway_rest_api.file_storage_api.root_resource_id
  path_part   = "executions"
}

resource "aws_api_gateway_resource" "execution_arn" {
  rest_api_id = aws_api_gateway_rest_api.file_storage_api.id
  parent_id   = aws_api_gateway_resource.execution.id
  path_part   = "{executionArn}"
}

# GET execution method
resource "aws_api_gateway_method" "get_execution" {
  rest_api_id   = aws_api_gateway_rest_api.file_storage_api.id
  resource_id   = aws_api_gateway_resource.execution_arn.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_integration" "get_execution" {
  rest_api_id = aws_api_gateway_rest_api.file_storage_api.id
  resource_id = aws_api_gateway_resource.execution_arn.id
  http_method = aws_api_gateway_method.get_execution.http_method
  type        = "AWS_PROXY"
  integration_http_method = "POST"
  uri         = aws_lambda_function.get_execution_result.invoke_arn
}

resource "aws_api_gateway_method_response" "get_execution_response_200" {
  rest_api_id = aws_api_gateway_rest_api.file_storage_api.id
  resource_id = aws_api_gateway_resource.execution_arn.id
  http_method = aws_api_gateway_method.get_execution.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
  }
}

resource "aws_lambda_permission" "get_execution_result_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_execution_result.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.file_storage_api.execution_arn}/*"
}

# Resource for /files/{fileId}
resource "aws_api_gateway_resource" "file" {
  rest_api_id = aws_api_gateway_rest_api.file_storage_api.id
  parent_id   = aws_api_gateway_resource.files.id
  path_part   = "{fileId}"
}

# DOWNLOAD file method
resource "aws_api_gateway_method" "download_file" {
  rest_api_id   = aws_api_gateway_rest_api.file_storage_api.id
  resource_id   = aws_api_gateway_resource.file.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_integration" "download_file" {
  rest_api_id = aws_api_gateway_rest_api.file_storage_api.id
  resource_id = aws_api_gateway_resource.file.id
  http_method = aws_api_gateway_method.download_file.http_method
  type        = "AWS_PROXY"
  integration_http_method = "POST"
  uri         = aws_lambda_function.download_file.invoke_arn
}

# Cognito Authorizer
resource "aws_api_gateway_authorizer" "cognito" {
  name            = "cognito-authorizer"
  rest_api_id     = aws_api_gateway_rest_api.file_storage_api.id
  type            = "COGNITO_USER_POOLS"
  provider_arns   = [aws_cognito_user_pool.file_storage_pool.arn]
}

# Deployment
resource "aws_api_gateway_deployment" "api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.file_storage_api.id
  depends_on = [
    aws_api_gateway_integration.list_files,
    aws_api_gateway_integration.upload_file,
    aws_api_gateway_integration.download_file,
    aws_api_gateway_integration.get_execution,
    aws_api_gateway_integration.cors_preflight
  ]
}

# Stage
resource "aws_api_gateway_stage" "api_stage" {
  deployment_id = aws_api_gateway_deployment.api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.file_storage_api.id
  stage_name    = var.environment
}

# Lambda permissions
resource "aws_lambda_permission" "list_files_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.list_files.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.file_storage_api.execution_arn}/*"
}

resource "aws_lambda_permission" "download_file_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.download_file.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.file_storage_api.execution_arn}/*"
}

resource "aws_api_gateway_method_settings" "general_settings" {
  rest_api_id = aws_api_gateway_rest_api.file_storage_api.id
  stage_name  = aws_api_gateway_stage.api_stage.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled        = true
    logging_level         = "INFO"
    data_trace_enabled    = true
  }
}