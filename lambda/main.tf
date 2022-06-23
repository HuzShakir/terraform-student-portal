
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

  source_dir  = "${path.module}/../terraform-lambda-student-portal"
  output_path = "${path.module}/../terraform-lambda-student-portal.zip"
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
      USER_POOL_ID="${var.terra_sportal_id}",
      USER_POOL_CLIENT_ID="${var.terra_sportal_client_id}",
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

