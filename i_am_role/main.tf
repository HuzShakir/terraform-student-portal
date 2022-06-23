
resource "aws_iam_role_policy" "terra_sportal_policy" {
  name = "role_policy"
  role = var.lambda_exec_id

  policy = <<-EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "cognito-idp:*"
      ],
      "Effect": "Allow",
      "Resource": "${var.cognito_arn}"
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
      "Resource":"${var.dynamodb_arn}"
    }
  ]
}
EOF
}


resource "aws_s3_bucket_policy" "allow_access_from_another_account" {
  bucket = var.frontend
  policy = <<EOF
  {
    "Version": "2008-10-17",
    "Id": "PolicyForCloudFrontPrivateContent",
    "Statement": [
        {
            "Sid": "1",
            "Effect": "Allow",
            "Principal": {
                "AWS": "${var.cloudfront_iam_arn}"
            },
            "Action": "s3:GetObject",
            "Resource": "${var.frontend_bucket_arn}/*"
        }
    ]
}
  EOF
}