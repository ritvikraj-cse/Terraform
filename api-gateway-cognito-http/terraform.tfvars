region                   = "ap-south-1"
api_name                 = "ritvik-rest-api"
cognito_user_pool_name   = "ritvik-user-pool"
stage_name               = "dev"
admin_temp_password      = "TempPass123!"  # Change this before production

endpoint_config = {
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
