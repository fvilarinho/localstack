# Lambda role definition.
resource "aws_iam_role" "lambda" {
  name = "lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# Attaches the default policy to make it executable/observable.
resource "aws_iam_role_policy_attachment" "lambda" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"

  depends_on = [ aws_iam_role.lambda ]
}

# Allows invoke from S3.
resource "aws_lambda_permission" "mybucket-mylambda" {
  source_arn    = aws_s3_bucket.mybucket.arn
  function_name = aws_lambda_function.mylambda.function_name
  principal     = "s3.amazonaws.com"
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"

  depends_on = [
    aws_lambda_function.mylambda,
    aws_s3_bucket.mybucket
  ]
}

# Allow API Gateway to invoke the Lambda.
resource "aws_lambda_permission" "myapi-mydynamodbtable" {
  source_arn    = "${aws_api_gateway_rest_api.myapi.execution_arn}/*/*"
  function_name = aws_lambda_function.mydynamodbtable.function_name
  principal     = "apigateway.amazonaws.com"
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"

  depends_on = [
    aws_api_gateway_rest_api.myapi, 
    aws_lambda_function.mydynamodbtable
  ]
}

# Allows put/delete/scan actions in DynamoDB table via Lambda function.
resource "aws_iam_role_policy" "lambda-mydynamodbtable" {
  name = "lambda-my-dynamodb-table"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:DeleteItem",
          "dynamodb:Scan"
        ]
        Resource = aws_dynamodb_table.mydynamodbtable.arn
      }
    ]
  })

  depends_on = [
    aws_dynamodb_table.mydynamodbtable,
    aws_iam_role.lambda
  ]
}