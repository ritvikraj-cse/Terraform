# S3 - Backend

# resource "aws_s3_bucket" "mybucket" {
#   bucket = "ritvik-rest-api-bucket"

#   tags = {
#     Environment = "Dev"
#   }
# }

# REST API
resource "aws_api_gateway_rest_api" "this" {
  name        = "${var.api_name}-${var.environment}"
  description = "Mock REST API with IAM auth, headers, query, path params"
}

# Endpoints- /users/{user_id}
# Resources
resource "aws_api_gateway_resource" "users" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = "users"
}

# /users/123
resource "aws_api_gateway_resource" "user_id" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_resource.users.id
  path_part   = "{user_id}"
}

# Methods
resource "aws_api_gateway_method" "methods" {
  for_each = toset(var.methods)

  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.user_id.id
  http_method   = each.key
  authorization = "AWS_IAM"

  request_parameters = {
    "method.request.path.user_id"   = true
    "method.request.querystring.qp"  = false
    "method.request.header.H-Test"  = false
  }
}

# Integrations
resource "aws_api_gateway_integration" "integrations" {
  for_each = toset(var.methods)

  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.user_id.id
  http_method = aws_api_gateway_method.methods[each.key].http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = <<EOF
#set($inputRoot = $input.path('$'))
{
  "statusCode": 200,
  "method": "${each.key}",
  "pathParam": "$input.params('user_id')",
  "queryParam": "$input.params('qp')",
  "headerParam": "$input.params('H-Test')",
  "body": $input.json('$')
}
EOF
  }
}


# Method Responses
resource "aws_api_gateway_method_response" "responses" {
  for_each = toset(var.methods)

  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.user_id.id
  http_method = aws_api_gateway_method.methods[each.key].http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.X-Custom" = true
    "method.response.header.H-Test"   = true
  }
}

# Integration Responses

resource "aws_api_gateway_integration_response" "integration_responses" {
  for_each = toset(var.methods)

  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.user_id.id
  http_method = aws_api_gateway_method.methods[each.key].http_method
  status_code = aws_api_gateway_method_response.responses[each.key].status_code

  response_templates = {
    "application/json" = <<EOF
{
  "message": "${each.key} success",
  "pathParam": "$input.params('user_id')",
  "queryParam": "$input.params('qp')",
  "headerParam": "$input.params('H-Test')",
  "body": $input.json('$.body')
}
EOF
  }

  response_parameters = {
    "method.response.header.X-Custom" = "'CustomHeaderValue'"
    "method.response.header.H-Test"   = "integration.response.header.H-Test"
  }
}

# Deployment
resource "aws_api_gateway_deployment" "this" {
  depends_on = [
    aws_api_gateway_integration.integrations,
    aws_api_gateway_method_response.responses,
    aws_api_gateway_integration_response.integration_responses
  ]
  rest_api_id = aws_api_gateway_rest_api.this.id

  # This forces a new deployment when API config changes
  triggers = {
    redeployment = sha1(jsonencode({
      rest_api_id       = aws_api_gateway_rest_api.this.id
      resources         = aws_api_gateway_resource.user_id.id
      methods           = var.methods
    }))
  }

  lifecycle {
    create_before_destroy = true #  Prevents "active stage" deletion errors
  }
}



resource "aws_api_gateway_stage" "this" {
  stage_name    = var.environment
  rest_api_id   = aws_api_gateway_rest_api.this.id
  deployment_id = aws_api_gateway_deployment.this.id
}

# IAM User & Policy
resource "aws_iam_user" "api_user" {
  name = "${var.api_name}-${var.environment}-user"
}

resource "aws_iam_access_key" "api_user_key" {
  user = aws_iam_user.api_user.name
}

resource "aws_iam_policy" "api_user_policy" {
  name   = "${var.api_name}-${var.environment}-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "execute-api:Invoke"
      Resource = ["${aws_api_gateway_rest_api.this.execution_arn}/*/*/*"]
    }]
  })
}

resource "aws_iam_user_policy_attachment" "attach_api_policy" {
  user       = aws_iam_user.api_user.name
  policy_arn = aws_iam_policy.api_user_policy.arn
}
