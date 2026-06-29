# API Gateway definition.
resource "aws_api_gateway_rest_api" "myapi" {
  name = "my-api"

  tags = {
    Name        = "My API"
    Environment = var.environment
  }
}

# API Gateway endpoint.
resource "aws_api_gateway_resource" "myapi" {
  rest_api_id = aws_api_gateway_rest_api.myapi.id
  parent_id   = aws_api_gateway_rest_api.myapi.root_resource_id
  path_part   = "get_items"

  depends_on = [ aws_api_gateway_rest_api.myapi ]
}

# API Gateway endpoint method.
resource "aws_api_gateway_method" "myapi" {
  rest_api_id   = aws_api_gateway_rest_api.myapi.id
  resource_id   = aws_api_gateway_resource.myapi.id
  http_method   = "GET"
  authorization = "NONE"
  api_key_required = false

  depends_on = [ 
    aws_api_gateway_rest_api.myapi,
    aws_api_gateway_resource.myapi
   ]
}

# Wire API Gateway endpoint with the Lambda function.
resource "aws_api_gateway_integration" "myapi" {
  rest_api_id             = aws_api_gateway_rest_api.myapi.id
  resource_id             = aws_api_gateway_resource.myapi.id
  http_method             = aws_api_gateway_method.myapi.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${aws_lambda_function.mydynamodbtable.arn}/invocations"

  depends_on = [
    aws_api_gateway_rest_api.myapi,
    aws_api_gateway_resource.myapi,
    aws_api_gateway_method.myapi,
    aws_lambda_function.mydynamodbtable
  ]
}

# Deploy the API Gateway.
resource "aws_api_gateway_deployment" "myapi" {
  rest_api_id = aws_api_gateway_rest_api.myapi.id

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [ 
    aws_api_gateway_rest_api.myapi,
    aws_api_gateway_integration.myapi 
  ]
}

# Define the API Gateway stage (version).
resource "aws_api_gateway_stage" "myapi" {
  rest_api_id   = aws_api_gateway_rest_api.myapi.id
  deployment_id = aws_api_gateway_deployment.myapi.id
  stage_name    = "v1"

  tags = {
    Name        = "My API Stage"
    Environment = var.environment
  }

  depends_on = [
    aws_api_gateway_rest_api.myapi,
    aws_api_gateway_deployment.myapi
  ]
}