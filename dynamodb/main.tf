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
