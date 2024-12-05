resource "aws_cognito_user_pool" "file_storage_pool" {
  name = "${var.project_name}-user-pool"

  # Basic password policy
  password_policy {
    minimum_length    = 6
    require_lowercase = true
    require_numbers   = false
    require_symbols   = false
    require_uppercase = false
  }

  # Email as username
  username_attributes = ["email"]
  auto_verified_attributes = ["email"]

  # Email verification
  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE"
    email_subject = "Your verification code"
    email_message = "Your verification code is {####}"
  }
}

# Cognito User Pool Client
resource "aws_cognito_user_pool_client" "file_storage_client" {
  name         = "${var.project_name}-client"
  user_pool_id = aws_cognito_user_pool.file_storage_pool.id

  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]

  # Token configuration
  id_token_validity       = 1
  access_token_validity   = 1
  refresh_token_validity  = 30
}
