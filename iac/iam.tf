# Lambda role definition.
resource "aws_iam_role" "mylambda" {
  name = "my-lambda"

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
resource "aws_iam_role_policy_attachment" "mylambda" {
  role       = aws_iam_role.mylambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"

  depends_on = [ aws_iam_role.mylambda ]
}

# Allows invoke permission from S3.
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

# Allows put/delete actions in DynamoDB table.
resource "aws_iam_role_policy" "mylambda-mydynamodbtable" {
  name = "my-lambda-my-dynamodb-table"
  role = aws_iam_role.mylambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:DeleteItem"
        ]
        Resource = aws_dynamodb_table.mydynamodbtable.arn
      }
    ]
  })

  depends_on = [
    aws_dynamodb_table.mydynamodbtable,
    aws_iam_role.mylambda
  ]
}