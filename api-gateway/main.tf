resource "aws_apigatewayv2_api" "lambda" {
  name          = "serverless_lambda_gw"
  protocol_type = "HTTP"
  cors_configuration {
    allow_headers = ["*"]
    allow_methods  = ["GET","POST","DELETE","OPTIONS"]
  allow_origins = [ "*" ]
  
  }
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

  integration_uri    = var.lambda_invoke_arn
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


resource "aws_apigatewayv2_authorizer" "api_gw_authorizer" {
  api_id           = aws_apigatewayv2_api.lambda.id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  name             = "JWTAuthorizer"

  jwt_configuration {
    audience = var.terra_sportal_client_id
    issuer   = "https://${var.terra_sportal_endpoint}"
  }
}
resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.lambda.execution_arn}/*/*"
}
