resource "aws_iam_role" "codebuild" {
  name = "codebuild_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "codebuild" {
  role = aws_iam_role.codebuild.name

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Resource": [
        "*"
      ],
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:*"
      ],
      "Resource": [
        "*"
      ]
    }
  ]
}
POLICY
}

resource "aws_codebuild_project" "terra_code_build" {
  name           = "terra_code_build"
  description    = "Codebuild terraform"
  build_timeout  = "5"
  queued_timeout = "5"

  service_role = aws_iam_role.codebuild.arn

  artifacts {
    type = "CODEPIPELINE"

  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

  }

  source {
    buildspec = <<EOF
version: 0.2

phases:
  # install:
  #   commands:
  #     - echo Installing Node 16...
  #     - curl -sL https://deb.nodesource.com/setup_16.x | bash -
  #     - apt install -y nodejs
  #     - echo Installing Yarn...
  #     - curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
  #     - echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
  #     - apt install --no-install-recommends yarn
  pre_build:
      commands:
      # - echo Installing dependencies...
      # - yarn
      - echo installing dependencies
      - npm install 
  build:
      commands:
      # - echo Building...
      # - yarn build
      - echo Building...
      - npm run build
artifacts:
  files:
      - "**/*"
  discard-paths: no
  base-directory: build
    EOF
    type            = "CODEPIPELINE"

  }

}