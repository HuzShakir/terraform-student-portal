
resource "aws_cognito_user_pool" "terra_sportal" {
  name = "terraform-student-portal"

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_phone_number"
      priority = 2
    }
  }
  auto_verified_attributes = [ "email" ]
  password_policy {
    minimum_length = 8
    require_lowercase = true
    require_numbers = true
    require_symbols = true
    require_uppercase = true
    temporary_password_validity_days = 30
  }
  schema {
    name = "Department"
    attribute_data_type = "String"
    mutable = true
    required = false
    string_attribute_constraints {
      min_length = 1
      max_length = 256
    }
  }
  schema {
    name = "ClassNo"
    attribute_data_type = "String"
    mutable = true
    required = false
    string_attribute_constraints {
      min_length = 1
      max_length = 256
    }
  }
  schema {
    name = "email"
    mutable = true
    required = true
    attribute_data_type = "String"
    string_attribute_constraints {
      min_length = 1
      max_length = 256
    }
  }
  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }
  username_configuration {
    case_sensitive = true
  }
  
}
resource "aws_cognito_user_pool_client" "terra_sportal_client" {
  name = "client"

  user_pool_id = aws_cognito_user_pool.terra_sportal.id
  explicit_auth_flows = [ "ALLOW_ADMIN_USER_PASSWORD_AUTH","ALLOW_CUSTOM_AUTH","ALLOW_USER_PASSWORD_AUTH","ALLOW_USER_SRP_AUTH","ALLOW_REFRESH_TOKEN_AUTH" ]
  generate_secret = false
  prevent_user_existence_errors = "ENABLED"
  supported_identity_providers = [ "COGNITO" ]
  refresh_token_validity = 30
  access_token_validity = 1
  id_token_validity = 1
  enable_token_revocation = true
} 


resource "aws_cognito_user_group" "Student" {
  name         = "Student"
  user_pool_id = aws_cognito_user_pool.terra_sportal.id
}

resource "aws_cognito_user_group" "Faculty" {
  name         = "Faculty"
  user_pool_id = aws_cognito_user_pool.terra_sportal.id
}
resource "aws_cognito_user_group" "SuperAdmin" {
  name         = "SuperAdmin"
  user_pool_id = aws_cognito_user_pool.terra_sportal.id
}
