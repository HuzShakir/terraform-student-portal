output "terra_sportal_arn"  {
  value = aws_cognito_user_pool.terra_sportal.arn
}

output "terra_sportal_endpoint" {
  value = aws_cognito_user_pool.terra_sportal.endpoint
}

output "terra_sportal_id" {
  value = aws_cognito_user_pool.terra_sportal.id
}

output "terra_sportal_client_id" {
  value=aws_cognito_user_pool_client.terra_sportal_client.id
}