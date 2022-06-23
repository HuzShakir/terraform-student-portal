terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.2.0"
    }
  }

  required_version = "~> 1.0"
}

provider "aws" {
  region = var.aws_region
}
module "cognito" {
  source = "./cognito"
}

module "lambda" {
  source = "./lambda"
  table_name= "${module.dynamodb.table_name}"
  terra_sportal_id=       "${module.cognito.terra_sportal_id}"
  terra_sportal_client_id="${module.cognito.terra_sportal_client_id}"
  depends_on = [
    module.cognito
  ]
}

module "api_gateway" {
  source = "./api-gateway"
  lambda_invoke_arn=module.lambda.lambda_invoke_arn
  terra_sportal_endpoint=module.cognito.terra_sportal_endpoint
  terra_sportal_client_id=[module.cognito.terra_sportal_client_id]
  lambda_name = module.lambda.lambda_name
  depends_on = [
    module.lambda
  ]
}

module "dynamodb" {
  source = "./dynamodb"
}

module "aws_iam_policies" {
  source = "./i_am_role"
  lambda_exec_id = module.lambda.lambda_exec_id
  cognito_arn = module.cognito.terra_sportal_arn
  dynamodb_arn = module.dynamodb.arn
  frontend = module.pipeline.frontend_bucket_id
  frontend_bucket_arn = module.pipeline.frontend_bucket_arn
  cloudfront_iam_arn = module.cloudfront.iam_arn
  depends_on = [
    module.pipeline

  ]
}

module "codebuild" {
  source="./codebuild"
}

module "pipeline" {
  source = "./codepipeline"
  codebuild_name=module.codebuild.name
  user_pool_id = module.cognito.terra_sportal_id
  user_pool_client_id = module.cognito.terra_sportal_client_id
  endpoint = module.api_gateway.endpoint_url
  client_url = module.cloudfront.domain_name
}

module "cloudfront" {
  source = "./cloudfront"
  domain_name = module.pipeline.s3_regional_domain_name
}
