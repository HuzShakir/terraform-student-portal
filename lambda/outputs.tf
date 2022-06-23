output "lambda_id" {
  value=aws_lambda_function.student_lambda_terraform.id
}

output "lambda_invoke_arn" {
  value = aws_lambda_function.student_lambda_terraform.invoke_arn
}

output "lambda_name" {
  value = aws_lambda_function.student_lambda_terraform.function_name
}
output "lambda_exec_id" {
  value = aws_iam_role.lambda_exec.id
}