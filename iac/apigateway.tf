# REST API Gateway.
resource "aws_api_gateway_rest_api" "myapi" {
  name = "my-api"

  tags = {
    Name        = "My API"
    Environment = var.environment
  }
}

# /items resource.
resource "aws_api_gateway_resource" "myapi" {
  rest_api_id = aws_api_gateway_rest_api.myapi.id
  parent_id   = aws_api_gateway_rest_api.myapi.root_resource_id
  path_part   = "items"

  depends_on = [ aws_api_gateway_rest_api.myapi ]
}

# GET /items method.
resource "aws_api_gateway_method" "myapi" {
  rest_api_id   = aws_api_gateway_rest_api.myapi.id
  resource_id   = aws_api_gateway_resource.myapi.id
  http_method   = "GET"
  authorization = "NONE"

  depends_on = [ 
    aws_api_gateway_rest_api.myapi,
    aws_api_gateway_resource.myapi
   ]
}

# Wire GET /items to the Lambda function.
resource "aws_api_gateway_integration" "myapi" {
  rest_api_id             = aws_api_gateway_rest_api.myapi.id
  resource_id             = aws_api_gateway_resource.myapi.id
  http_method             = aws_api_gateway_method.myapi.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.mydynamodbtable.invoke_arn

  depends_on = [
    aws_api_gateway_rest_api.myapi,
    aws_api_gateway_resource.myapi,
    aws_api_gateway_method.myapi,
    aws_lambda_function.mydynamodbtable
  ]
}

# Deploy the API.
resource "aws_api_gateway_deployment" "myapi" {
  rest_api_id = aws_api_gateway_rest_api.myapi.id

  depends_on = [ 
    aws_api_gateway_rest_api.myapi,
    aws_api_gateway_integration.myapi 
  ]
}

# Stage.
resource "aws_api_gateway_stage" "myapi" {
  rest_api_id   = aws_api_gateway_rest_api.myapi.id
  deployment_id = aws_api_gateway_deployment.myapi.id
  stage_name    = "v1"

  tags = {
    Name        = "My API Stage"
    Environment = var.environment
  }

  depends_on = [ 

   ]
}
