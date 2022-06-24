
## Serverless Student Portal with Terraform

This project deploys the backend of student-portal with Terraform.

# Stack deployed
- Cognito UserPool
- DynamoDB Table
- Lambda function with API
- IAM Role for Lambda
- API Gateway that invokes the API Lambda function 
- CodeBuild project
- CodePipeline which:
	- Monitors frontend repo as a source
	- Builds the repo with AWS Codebuild service 
	- Deploys the build into a s3 bucket
- CloudFront Distribution for the s3 bucket

# Install
```bash
$ terraform init
$ terraform apply
```

---

# Student Portal
  

## Features

  

- Allow Super Admin User to log in

- Allow Super Admin User to create Faculty Users

- Allow Faculty Users to create other Faculty Users

- Allow Faculty Users to create Student User Account with Department and Class No.

- Allow Faculty Users to update Student User Account with Class No

- Allow Students to log in and check their current Department and Class No

- Allow Faculty Users to Add/Edit Student detail with “key/value” like combinations

- For example, they can set these detail

- Key: “Semester 1 Result”, Value: JSON object data

- Key: “Year 1 Report”, Value: JSON object data

- Key: “Workshop ABC Report” Value: JSON object data

- Students can log in and check all the detail created for their user and view the UI

- Students CAN ONLY VIEW the detail, they can not modify the data

- Faculty members can ADD/UPDATE/VIEW detail for any student based on the Student ID or Email address

