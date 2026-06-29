# Package the lambda function.
data "archive_file" "mylambda" {
  type        = "zip"
  source_file = "../src/lambda/mylambda.py"
  output_path = "../temp/lambda/mylambda.zip"
}

# Lambda function definition. It will be triggered when a object was added/removed in the S3 bucket.
resource "aws_lambda_function" "mylambda" {
  function_name    = "my-lambda"
  handler          = "mylambda.handler"
  runtime          = "python3.12"
  timeout          = 10
  filename         = data.archive_file.mylambda.output_path
  source_code_hash = data.archive_file.mylambda.output_base64sha256
  role             = aws_iam_role.lambda.arn

  # Pass the API endpoint to the lambda function, required to make API calls using boto3 library.
  environment {
    variables = {
      ENDPOINT_URL = "http://${var.endpoint}"
    }
  }

  tags = {
    Name        = "My Lambda"
    Environment = var.environment
  }

  depends_on = [
    data.archive_file.mylambda,
    aws_iam_role.lambda
  ]
}

data "archive_file" "mydynamodbtable" {
  type        = "zip"
  source_file = "../src/lambda/mydynamodbtable.py"
  output_path = "../temp/lambda/mydynamodbtable.zip"
}

# Lambda function to list DynamoDB items, invoked by API Gateway.
resource "aws_lambda_function" "mydynamodbtable" {
  function_name    = "my-dynamodb-table"
  handler          = "mydynamodbtable.handler"
  runtime          = "python3.12"
  timeout          = 10
  filename         = data.archive_file.mydynamodbtable.output_path
  source_code_hash = data.archive_file.mydynamodbtable.output_base64sha256
  role             = aws_iam_role.lambda.arn

  environment {
    variables = {
      ENDPOINT_URL = "http://${var.endpoint}"
    }
  }

  tags = {
    Name        = "My DynamoDB Table"
    Environment = var.environment
  }

  depends_on = [
    data.archive_file.mydynamodbtable,
    aws_iam_role.lambda
  ]
}
