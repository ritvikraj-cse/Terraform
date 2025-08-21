terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.9.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# -----------------------------
# Cognito User Pool
# -----------------------------
resource "aws_cognito_user_pool" "this" {
  name = var.cognito_user_pool_name

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_cognito_user_pool_client" "this" {
  name            = "${var.cognito_user_pool_name}-client"
  user_pool_id    = aws_cognito_user_pool.this.id
  generate_secret = false

  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_ADMIN_USER_PASSWORD_AUTH"
  ]
}

# -----------------------------
# Cognito Groups
# -----------------------------
locals {
  all_groups = toset(flatten([
    for endpoint, methods in var.endpoint_config : [
      for method, cfg in methods : cfg.groups
    ]
  ]))
}

resource "aws_cognito_user_group" "groups" {
  for_each     = local.all_groups
  user_pool_id = aws_cognito_user_pool.this.id
  name         = each.key
  precedence   = 1
}

# -----------------------------
# Example Admin User
# -----------------------------
resource "aws_cognito_user" "admin_user" {
  username             = "admin"
  user_pool_id         = aws_cognito_user_pool.this.id
  temporary_password   = var.admin_temp_password
  force_alias_creation = true
  message_action       = "SUPPRESS"
}

resource "aws_cognito_user_in_group" "admin_membership" {
  for_each    = { for g in local.all_groups : g => g if g == "Admin" }
  user_pool_id = aws_cognito_user_pool.this.id
  username     = aws_cognito_user.admin_user.username
  group_name   = each.key
}

# -----------------------------
# API Gateway REST API
# -----------------------------
resource "aws_api_gateway_rest_api" "this" {
  name        = var.api_name
  description = "API Gateway with Cognito Authorizer"
}

# -----------------------------
# API Resources
# -----------------------------
resource "aws_api_gateway_resource" "users" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = "users"
}

resource "aws_api_gateway_resource" "user_id" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_resource.users.id
  path_part   = "{id}"
}

locals {
  endpoint_ids = {
    "/users"      = aws_api_gateway_resource.users.id,
    "/users/{id}" = aws_api_gateway_resource.user_id.id
  }
}

# -----------------------------
# Cognito Authorizer
# -----------------------------
resource "aws_api_gateway_authorizer" "cognito" {
  name            = "CognitoAuthorizer"
  rest_api_id     = aws_api_gateway_rest_api.this.id
  identity_source = "method.request.header.Authorization"
  type            = "COGNITO_USER_POOLS"
  provider_arns   = [aws_cognito_user_pool.this.arn]
}

# -----------------------------
# Local map for dynamic methods
# -----------------------------
locals {
  all_methods = {
    for pair in flatten([
      for endpoint, methods in var.endpoint_config : [
        for method, cfg in methods : {
          key      = "${endpoint} ${method}"
          endpoint = endpoint
          method   = method
          config   = cfg
        }
      ]
    ]) : pair.key => {
      endpoint = pair.endpoint
      method   = pair.method
      config   = pair.config
    }
  }
}

# -----------------------------
# Methods
# -----------------------------
resource "aws_api_gateway_method" "methods" {
  for_each = local.all_methods

  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = local.endpoint_ids[each.value.endpoint]
  http_method   = each.value.method
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id

  request_parameters = each.value.endpoint == "/users/{id}" ? {
    "method.request.path.id" = true
  } : {}
}

# -----------------------------
# Integrations
# -----------------------------
resource "aws_api_gateway_integration" "integrations" {
  for_each = local.all_methods

  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = local.endpoint_ids[each.value.endpoint]
  http_method             = each.value.method
  integration_http_method = each.value.method
  type                    = "HTTP_PROXY"
  uri                     = each.value.config.url

  request_parameters = each.value.endpoint == "/users/{id}" ? {
    "integration.request.path.id" = "method.request.path.id"
  } : {}

  depends_on = [aws_api_gateway_method.methods]
}

# -----------------------------
# Method Responses
# -----------------------------
resource "aws_api_gateway_method_response" "method_responses" {
  for_each = local.all_methods

  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = local.endpoint_ids[each.value.endpoint]
  http_method = each.value.method
  status_code = "200"

  depends_on = [aws_api_gateway_method.methods]
}

# -----------------------------
# Integration Responses
# -----------------------------
resource "aws_api_gateway_integration_response" "integration_responses" {
  for_each = local.all_methods

  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = local.endpoint_ids[each.value.endpoint]
  http_method = each.value.method
  status_code = aws_api_gateway_method_response.method_responses[each.key].status_code

  depends_on = [
    aws_api_gateway_integration.integrations,
    aws_api_gateway_method_response.method_responses
  ]
}

# -----------------------------
# Deployment & Stage
# -----------------------------
resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id

  triggers = {
    redeployment = timestamp()
  }

  depends_on = [
    aws_api_gateway_method.methods,
    aws_api_gateway_integration.integrations
  ]
}

resource "aws_api_gateway_stage" "dev" {
  stage_name    = var.stage_name
  rest_api_id   = aws_api_gateway_rest_api.this.id
  deployment_id = aws_api_gateway_deployment.this.id
}

# -----------------------------
# Simplified Resource Policy
# -----------------------------
resource "aws_api_gateway_rest_api_policy" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = flatten([
      for endpoint, methods in var.endpoint_config : [
        for method, cfg in methods : {
          Effect    = "Allow"
          Principal = { "AWS": "*" }
          Action    = "execute-api:Invoke"
          Resource  = [
            "${aws_api_gateway_rest_api.this.execution_arn}/${aws_api_gateway_stage.dev.stage_name}/${upper(method)}${endpoint}",
            "${aws_api_gateway_rest_api.this.execution_arn}/${aws_api_gateway_stage.dev.stage_name}/${upper(method)}${endpoint}/*"
          ]
          Condition = {
            StringLike = {
              "cognito:groups" = cfg.groups
            }
          }
        }
      ]
    ])
  })
}

# -----------------------------
# Outputs
# -----------------------------
output "cognito_user_pool_id" {
  description = "ID of the Cognito User Pool"
  value       = aws_cognito_user_pool.this.id
}

output "cognito_client_id" {
  description = "ID of the Cognito User Pool Client"
  value       = aws_cognito_user_pool_client.this.id
}

output "api_invoke_url" {
  description = "Invoke URL of the API Gateway"
  value       = "https://${aws_api_gateway_rest_api.this.id}.execute-api.${var.region}.amazonaws.com/${aws_api_gateway_stage.dev.stage_name}"
}

output "cognito_groups" {
  description = "List of Cognito Groups"
  value       = keys(aws_cognito_user_group.groups)
}

output "cognito_authorizer_id" {
  description = "ID of the API Gateway Cognito Authorizer"
  value       = aws_api_gateway_authorizer.cognito.id
}
