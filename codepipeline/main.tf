resource "random_pet" "codepipeline_bucket_name" {
  prefix = "terraform-student-portal"
  length = 4
}
resource "random_pet" "react_client" {
  prefix = "react-client"
  length = 6
}

resource "aws_codepipeline" "codepipeline" {
  name     = "terra_pipeline"

  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_bucket.bucket
    type     = "S3"

    # encryption_key {
    #   id   = data.aws_kms_alias.s3kmskey.arn
    #   type = "KMS"
    # }
  }

   stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn        = "${aws_codestarconnections_connection.github_connection.arn}"
        FullRepositoryId     = "HuzShakir/Student-portal-client"
        BranchName           = "main"
        OutputArtifactFormat = "CODE_ZIP"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"
    

      configuration = {
        "EnvironmentVariables" = jsonencode(
          [
            
              {
                name="REACT_APP_POOL_ID"
                value="${var.user_pool_id}"
                type="PLAINTEXT"
              },
              {
                name="REACT_APP_CLIENT_ID"
                value="${var.user_pool_client_id}"
                type="PLAINTEXT"
              },
              {
                name="REACT_APP_URL"
                value="${var.client_url}"
                type="PLAINTEXT"
              },
              {
                name="REACT_APP_ENDPOINT"
                value="${var.endpoint}"
                type="PLAINTEXT"
              }
            
          ]
        )
        ProjectName = var.codebuild_name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      category = "Deploy"
      configuration = {
        "BucketName" = aws_s3_bucket.react_client.id
        "Extract"    = "true"
      }
      input_artifacts = [
        "build_output",
      ]
      name             = "Deploy"
      owner            = "AWS"
      provider         = "S3"
      run_order        = 1
      version          = "1"
    }
  }
}

resource "aws_codestarconnections_connection" "github_connection" {
  name          = "student-portal-client"
  provider_type = "GitHub"
}

resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket = random_pet.codepipeline_bucket_name.id
}

resource "aws_s3_bucket" "react_client" {
  bucket = random_pet.react_client.id

}

resource "aws_s3_bucket_website_configuration" "site" {
  bucket = aws_s3_bucket.react_client.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

resource "aws_s3_bucket_acl" "react_client_bucket_acl" {
  bucket = aws_s3_bucket.react_client.id
    acl = "public-read-write"
}

resource "aws_s3_bucket_acl" "codepipeline_bucket_acl" {
  bucket = aws_s3_bucket.codepipeline_bucket.id
  acl    = "private"
}

resource "aws_iam_role" "codepipeline_role" {
  name = "terra-pipeline-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}



resource "aws_iam_role_policy" "codepipeline_policy" {
  name = "codepipeline_policy"
  role = aws_iam_role.codepipeline_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect":"Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetBucketVersioning",
        "s3:PutObjectAcl",
        "s3:PutObject",
        "s3:PutObjectVersionAcl"
      ],
      "Resource": [
        "${aws_s3_bucket.codepipeline_bucket.arn}",
        "${aws_s3_bucket.codepipeline_bucket.arn}/*",
        "${aws_s3_bucket.react_client.arn}",
        "${aws_s3_bucket.react_client.arn}/*",
        "arn:aws:s3:::react-student-portal-build",
        "arn:aws:s3:::react-student-portal-build/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "codestar-connections:UseConnection"
      ],
      "Resource": "${aws_codestarconnections_connection.github_connection.arn}"
    },
    {
      "Effect": "Allow",
      "Action": [
        "codebuild:BatchGetBuilds",
        "codebuild:StartBuild"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}
