
resource "aws_cognito_user_pool" "main" {
  name = "${var.project_name}-user-pool"

  alias_attributes = ["email"]
  
  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }

  user_pool_add_ons {
    advanced_security_mode = "ENFORCED"
  }

  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE"
    email_subject        = "Your ${var.project_name} verification code"
    email_message        = "Your verification code is {####}"
  }

  auto_verified_attributes = ["email"]

  schema {
    attribute_data_type = "String"
    name               = "email"
    required           = true
    mutable            = true
  }

  schema {
    attribute_data_type = "String"
    name               = "name"
    required           = true
    mutable            = true
  }

  tags = {
    Name = "${var.project_name}-user-pool"
  }
}

resource "aws_cognito_user_pool_client" "main" {
  name         = "${var.project_name}-user-pool-client"
  user_pool_id = aws_cognito_user_pool.main.id

  callback_urls                        = ["https://${aws_cloudfront_distribution.static_website_distribution.domain_name}/home.html"]
  logout_urls                          = ["https://${aws_cloudfront_distribution.static_website_distribution.domain_name}/"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["email", "openid", "profile"]
  supported_identity_providers         = ["COGNITO"]

  generate_secret     = false
  prevent_user_existence_errors = "ENABLED"

  access_token_validity  = 60  
  id_token_validity     = 60    
  refresh_token_validity = 30  

  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }

  read_attributes  = ["email", "name", "email_verified"]
  write_attributes = ["email", "name"]

  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]
}

resource "aws_cognito_user_pool_domain" "main" {
  domain       = "${var.project_name}-${random_id.bucket_suffix.hex}"
  user_pool_id = aws_cognito_user_pool.main.id
}


