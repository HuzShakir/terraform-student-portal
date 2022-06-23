variable "lambda_exec_id" {
  type = string
}

variable "cognito_arn" {
  type = string
}

variable "dynamodb_arn" {
  type = string
}
variable "frontend" {
  type = string
}
variable "frontend_bucket_arn" {
  type=string
}
variable "cloudfront_iam_arn" {
  type = string
}