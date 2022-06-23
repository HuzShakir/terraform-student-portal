output "s3_regional_domain_name" {
  value = aws_s3_bucket.react_client.bucket_regional_domain_name
}
output "frontend_bucket_id" {
  value = aws_s3_bucket.react_client.id
}
output "frontend_bucket_arn" {
  value = aws_s3_bucket.react_client.arn
}
