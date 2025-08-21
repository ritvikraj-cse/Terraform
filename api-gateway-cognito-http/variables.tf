variable "region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-south-1"
}

variable "api_name" {
  description = "Name of the API Gateway"
  type        = string
  default     = "ritvik-rest-api"
}

variable "cognito_user_pool_name" {
  description = "Name of the Cognito User Pool"
  type        = string
  default     = "ritvik-user-pool"
}

variable "stage_name" {
  description = "Stage name for API Gateway deployment"
  type        = string
  default     = "dev"
}

variable "admin_temp_password" {
  description = "Temporary password for the default admin user in Cognito"
  type        = string
  default     = "TempPass123!"
  sensitive   = true
}

variable "endpoint_config" {
  description = "Configuration for endpoints: methods, backend URLs, and allowed Cognito groups"
  type = map(map(object({
    url    = string
    groups = list(string)
  })))
  default = {
    "/users" = {
      GET = {
        url    = "https://jsonplaceholder.typicode.com/users"
        groups = ["Admin"]
      }
      POST = {
        url    = "https://jsonplaceholder.typicode.com/users"
        groups = ["Admin"]
      }
    }
    "/users/{id}" = {
      GET = {
        url    = "https://jsonplaceholder.typicode.com/users/{id}"
        groups = ["Admin", "User"]
      }
      PUT = {
        url    = "https://jsonplaceholder.typicode.com/users/{id}"
        groups = ["Admin"]
      }
      DELETE = {
        url    = "https://jsonplaceholder.typicode.com/users/{id}"
        groups = ["Admin"]
      }
    }
  }
}
