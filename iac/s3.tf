# S3 bucket definition.
resource "aws_s3_bucket" "mybucket" {
  bucket = "my-bucket"

  tags = {
    Name        = "My Bucket"
    Environment = var.environment
  }
}

# S3 bucket objects.
resource "aws_s3_object" "mybucket" {
  # List all files to upload.
  for_each = fileset("../src/s3", "**")

  bucket = aws_s3_bucket.mybucket.bucket
  key    = basename(each.value)
  source = "../src/s3/${each.value}"
  etag   = filemd5("../src/s3/${each.value}")

  depends_on = [
    aws_s3_bucket.mybucket,
    aws_dynamodb_table.mydynamodbtable,
    aws_s3_bucket_notification.mybucket-mylambda
  ]
}

# S3 bucket notification. It will trigger the lambda function when a event of put/delete was called.
resource "aws_s3_bucket_notification" "mybucket-mylambda" {
  bucket = aws_s3_bucket.mybucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.mylambda.arn

    events = [
      "s3:ObjectCreated:*",
      "s3:ObjectRemoved:*"
    ]
  }

  depends_on = [
    aws_s3_bucket.mybucket,
    aws_lambda_function.mylambda,
    aws_lambda_permission.mybucket-mylambda
  ]
}