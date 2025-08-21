output "api_invoke_url" {
  value       = "https://${aws_api_gateway_rest_api.this.id}.execute-api.${var.aws_region}.amazonaws.com/${var.environment}/users/{user_id}"
  description = "Invoke URL for API"
}


output "api_user_access_key" {
  value       = aws_iam_access_key.api_user_key.id
  description = "Access key for IAM user"
}

output "api_user_secret_key" {
  value       = aws_iam_access_key.api_user_key.secret
  description = "Secret key for IAM user"
  sensitive   = true
}
