terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.2.0"
    }
  }

  required_version = "~> 1.0"
}

provider "aws" {
  region = var.aws_region
}

resource "random_pet" "lambda_bucket_name" {
  prefix = "terraform-student-portal"
  length = 4
}

resource "aws_s3_bucket" "lambda_bucket" {
  bucket = random_pet.lambda_bucket_name.id

  force_destroy = true
}

data "archive_file" "lambda_student_portal" {
  type = "zip"

  source_dir  = "${path.module}/terraform-lambda-student-portal"
  output_path = "${path.module}/terraform-lambda-student-portal.zip"
}

resource "aws_s3_object" "lambda_student_portal" {
  bucket = aws_s3_bucket.lambda_bucket.id

  key    = "terraform-lambda-student-portal.zip"
  source = data.archive_file.lambda_student_portal.output_path

  etag = filemd5(data.archive_file.lambda_student_portal.output_path)
}

resource "aws_lambda_function" "student_lambda_terraform" {
  function_name = "terraform-lambda-student-portal"

  s3_bucket = aws_s3_bucket.lambda_bucket.id
  s3_key    = aws_s3_object.lambda_student_portal.key

  runtime = "nodejs14.x"
  handler = "handler.handler"

  source_code_hash = data.archive_file.lambda_student_portal.output_base64sha256
  environment {
    variables = {
      USERS_TABLE="Terraform_Student",
      USER_POOL_ID="${aws_cognito_user_pool.terra_sportal.id}",
      USER_POOL_CLIENT_ID="${aws_cognito_user_pool_client.terra_sportal_client.id}",
      REGION="ap-south-1",
    }
  }
  role = aws_iam_role.lambda_exec.arn
}

resource "aws_cloudwatch_log_group" "student_lambda_terraform_cloudwatch" {
  name = "/aws/lambda/${aws_lambda_function.student_lambda_terraform.function_name}"

  retention_in_days = 30
}

resource "aws_iam_role" "lambda_exec" {
  name = "serverless_lambda"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}


resource "aws_apigatewayv2_api" "lambda" {
  name          = "serverless_lambda_gw"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "lambda" {
  api_id = aws_apigatewayv2_api.lambda.id

  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw.arn

    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"

      }
    )
  }
}

resource "aws_apigatewayv2_integration" "student_portal" {
  api_id = aws_apigatewayv2_api.lambda.id

  integration_uri    = aws_lambda_function.student_lambda_terraform.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "get" {
  api_id = aws_apigatewayv2_api.lambda.id
  authorization_type = "JWT"
  authorizer_id = aws_apigatewayv2_authorizer.api_gw_authorizer.id
  route_key = "GET /{any+}"
  target    = "integrations/${aws_apigatewayv2_integration.student_portal.id}"
}
resource "aws_apigatewayv2_route" "post" {
  api_id = aws_apigatewayv2_api.lambda.id
  authorization_type = "JWT"
  authorizer_id = aws_apigatewayv2_authorizer.api_gw_authorizer.id
  route_key = "POST /{any+}"
  target    = "integrations/${aws_apigatewayv2_integration.student_portal.id}"
}
resource "aws_apigatewayv2_route" "delete" {
  api_id = aws_apigatewayv2_api.lambda.id
  authorization_type = "JWT"
  authorizer_id = aws_apigatewayv2_authorizer.api_gw_authorizer.id
  route_key = "DELETE /{any+}"
  target    = "integrations/${aws_apigatewayv2_integration.student_portal.id}"
}

resource "aws_cloudwatch_log_group" "api_gw" {
  name = "/aws/api_gw/${aws_apigatewayv2_api.lambda.name}"

  retention_in_days = 30
}

resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.student_lambda_terraform.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.lambda.execution_arn}/*/*"
}

resource "aws_apigatewayv2_authorizer" "api_gw_authorizer" {
  api_id           = aws_apigatewayv2_api.lambda.id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  name             = "JWTAuthorizer"

  jwt_configuration {
    audience = ["${aws_cognito_user_pool_client.terra_sportal_client.id}"]
    issuer   = "https://${aws_cognito_user_pool.terra_sportal.endpoint}"
  }
}

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

resource "aws_dynamodb_table" "Students" {
  name = "Terraform_Student"
  attribute {
    name = "id"
    type = "S"
  }
  attribute {
    name = "sk"
    type = "S"
  }
  hash_key = "id"
  range_key = "sk"
  billing_mode     = "PAY_PER_REQUEST" 
}

resource "aws_iam_role_policy" "terra_sportal_policy" {
  name = "role_policy"
  role = aws_iam_role.lambda_exec.id

  policy = <<-EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "cognito-idp:*"
      ],
      "Effect": "Allow",
      "Resource": "${aws_cognito_user_pool.terra_sportal.arn}"
    },
    {
      "Action": [
        "cognito-idp:*"
      ],
      "Effect": "Allow",
      "Resource": "${aws_cognito_user_pool.terra_sportal.arn}"
    },
    {
      "Action":[
        "dynamodb:Query",
        "dynamodb:Scan",
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
        "dynamodb:DeleteItem"
      ],
      "Effect":"Allow",
      "Resource":"${aws_dynamodb_table.Students.arn}"
    }
  ]
}
EOF
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