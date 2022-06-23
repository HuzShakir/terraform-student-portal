output "table_name" {
  value = aws_dynamodb_table.Students.name
}

output "arn" {
  value = aws_dynamodb_table.Students.arn
}