# DynamoDB table definition. This will store the entries of files in the S3 bucket.
resource "aws_dynamodb_table" "mydynamodbtable" {
  name         = "my-dynamodb-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "filename"

  attribute {
    name = "filename"
    type = "S"
  }

  tags = {
    Name        = "My DynamoDB Table"
    Environment = var.environment
  }
}