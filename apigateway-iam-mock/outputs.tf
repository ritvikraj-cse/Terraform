output "api_invoke_url" {
  value       = module.api_gateway.api_invoke_url
  description = "Invoke URL for API"
}

output "api_user_access_key" {
  value       = module.api_gateway.api_user_access_key
  description = "Access key for IAM user"
}

output "api_user_secret_key" {
  value       = module.api_gateway.api_user_secret_key
  description = "Secret key for IAM user"
  sensitive   = true
}
