output "dynamodb_table_name" {
  description = "Name of the DynamoDB table"
  value       = aws_dynamodb_table.shipment_trips.name
}

output "api_invoke_url" {
  description = "Invoke URL of the deployed API Gateway"
  value       = "https://${aws_api_gateway_rest_api.shipment_api.id}.execute-api.${var.aws_region}.amazonaws.com/${aws_api_gateway_stage.shipment_api_stage.stage_name}"
}

output "cognito_user_pool_id" {
  description = "ID of the Cognito User Pool"
  value       = aws_cognito_user_pool.users.id
}