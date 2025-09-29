provider "aws" {
  region = var.aws_region
}

# DynamoDB Table
resource "aws_dynamodb_table" "shipment_trips" {
  name         = var.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = var.dynamodb_partition_key
  range_key    = var.dynamodb_sort_key

  attribute {
    name = var.dynamodb_partition_key
    type = "S"
  }

  attribute {
    name = var.dynamodb_sort_key
    type = "S"
  }
}

# IAM Roles & Policies
resource "aws_iam_role" "insert_shipment_role" {
  name = "${var.insert_lambda_name}_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_policy" "insert_shipment_policy" {
  name   = "${var.insert_lambda_name}_policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["dynamodb:PutItem","dynamodb:GetItem"]
        Resource = aws_dynamodb_table.shipment_trips.arn
      },
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup","logs:CreateLogStream","logs:PutLogEvents"]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "insert_shipment_attach" {
  role       = aws_iam_role.insert_shipment_role.name
  policy_arn = aws_iam_policy.insert_shipment_policy.arn
}

resource "aws_iam_role" "retrieve_shipment_role" {
  name = "${var.retrieve_lambda_name}_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_policy" "retrieve_shipment_policy" {
  name   = "${var.retrieve_lambda_name}_policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["dynamodb:Query","dynamodb:GetItem"]
        Resource = aws_dynamodb_table.shipment_trips.arn
      },
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup","logs:CreateLogStream","logs:PutLogEvents"]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "retrieve_shipment_attach" {
  role       = aws_iam_role.retrieve_shipment_role.name
  policy_arn = aws_iam_policy.retrieve_shipment_policy.arn
}

# Lambda Functions
resource "aws_lambda_function" "insert_shipment" {
  function_name = var.insert_lambda_name
  handler       = "insert_shipment.lambda_handler"
  runtime       = "python3.11"
  role          = aws_iam_role.insert_shipment_role.arn
  filename      = var.insert_lambda_file

  environment {
    variables = {
      DYNAMODB_TABLE = var.dynamodb_table_name
    }
  }
}

resource "aws_lambda_function" "retrieve_shipment" {
  function_name = var.retrieve_lambda_name
  handler       = "retrieve_shipment.lambda_handler"
  runtime       = "python3.11"
  role          = aws_iam_role.retrieve_shipment_role.arn
  filename      = var.retrieve_lambda_file

  environment {
    variables = {
      DYNAMODB_TABLE = var.dynamodb_table_name
      MAX_LOCATIONS  = var.max_locations
    }
  }
}

# Cognito User Pool
resource "aws_cognito_user_pool" "users" {
  name = var.cognito_user_pool_name
}

# API Gateway
resource "aws_api_gateway_rest_api" "shipment_api" {
  name        = var.rest_api_name
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "api" {
  rest_api_id = aws_api_gateway_rest_api.shipment_api.id
  parent_id   = aws_api_gateway_rest_api.shipment_api.root_resource_id
  path_part   = "api"
}

resource "aws_api_gateway_resource" "v1" {
  rest_api_id = aws_api_gateway_rest_api.shipment_api.id
  parent_id   = aws_api_gateway_resource.api.id
  path_part   = "v1"
}

resource "aws_api_gateway_resource" "shipment_trips" {
  rest_api_id = aws_api_gateway_rest_api.shipment_api.id
  parent_id   = aws_api_gateway_resource.v1.id
  path_part   = "shipment-trips"
}

resource "aws_api_gateway_resource" "shipment_trips_id" {
  rest_api_id = aws_api_gateway_rest_api.shipment_api.id
  parent_id   = aws_api_gateway_resource.shipment_trips.id
  path_part   = "{shipmentId}"
}

# Methods & Integrations
resource "aws_api_gateway_method" "post_shipment" {
  rest_api_id   = aws_api_gateway_rest_api.shipment_api.id
  resource_id   = aws_api_gateway_resource.shipment_trips.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "post_shipment_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.shipment_api.id
  resource_id             = aws_api_gateway_resource.shipment_trips.id
  http_method             = aws_api_gateway_method.post_shipment.http_method
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = aws_lambda_function.insert_shipment.invoke_arn
}

resource "aws_api_gateway_method" "get_shipment" {
  rest_api_id   = aws_api_gateway_rest_api.shipment_api.id
  resource_id   = aws_api_gateway_resource.shipment_trips_id.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_integration" "get_shipment_lambda" {
  rest_api_id = aws_api_gateway_rest_api.shipment_api.id
  resource_id = aws_api_gateway_resource.shipment_trips_id.id
  http_method = aws_api_gateway_method.get_shipment.http_method
  type        = "AWS_PROXY"
  uri         = aws_lambda_function.retrieve_shipment.invoke_arn
}

# Cognito Authorizer
resource "aws_api_gateway_authorizer" "cognito" {
  name            = "Auth"
  rest_api_id     = aws_api_gateway_rest_api.shipment_api.id
  type            = "COGNITO_USER_POOLS"
  provider_arns   = [aws_cognito_user_pool.users.arn]
  identity_source = "method.request.header.Authorization"
}

# Deployment & Stage
resource "aws_api_gateway_deployment" "shipment_api_deployment" {
  depends_on = [
    aws_api_gateway_integration.post_shipment_lambda,
    aws_api_gateway_integration.get_shipment_lambda
  ]
  rest_api_id = aws_api_gateway_rest_api.shipment_api.id
  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.shipment_api))
  }
}

resource "aws_api_gateway_stage" "shipment_api_stage" {
  stage_name    = var.stage_name
  rest_api_id   = aws_api_gateway_rest_api.shipment_api.id
  deployment_id = aws_api_gateway_deployment.shipment_api_deployment.id
}