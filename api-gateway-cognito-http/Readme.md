
# AWS API Gateway with Cognito Authentication

This Terraform project provisions an **AWS API Gateway REST API** secured with **Cognito User Pool authentication**, supporting **path parameters**, **query parameters**, and **headers**.  
It also creates a **Cognito User Pool**, **Cognito groups**, and an **admin user**.

---

## 📂 Features

- AWS API Gateway REST API
- Cognito User Pool with groups
- Admin user creation
- Dynamic API methods and integrations
- IAM-based API Gateway resource policy
- Fully configurable endpoints and methods via Terraform variables

---

## 🗂️ Terraform Files

| File | Description |
|------|-------------|
| `main.tf` | Contains the AWS resources: Cognito, API Gateway, Methods, Integrations, Responses, Deployment |
| `variables.tf` | Defines configurable variables |
| `terraform.tfvars` | Provides values for variables |
| `backend.tf` | (Optional) S3 backend configuration for remote state |

---

## 🚀 Deployment Steps

1. **Initialize Terraform**
```bash
terraform init
```

2. **View Execution Plan**
```bash
terraform plan
```

3. **Apply Configuration**
```bash
terraform apply -auto-approve
```

### ✅ Outputs

| Output | Description |
|--------|-------------|
| api_invoke_url | Base URL for API Gateway |
| cognito_authorizer_id | ID of the API Gateway Cognito Authorizer |
| cognito_client_id | Cognito User Pool Client ID |
| cognito_groups | List of Cognito groups |
| cognito_user_pool_id | Cognito User Pool ID |

---

## 🔑 Admin User Authentication

### Step 1: Initiate Admin Authentication
```bash
aws cognito-idp admin-initiate-auth   --user-pool-id <cognito_user_pool_id>   --client-id <cognito_client_id>   --auth-flow ADMIN_USER_PASSWORD_AUTH   --auth-parameters USERNAME=admin,PASSWORD=<admin_temp_password>
```

### Step 2: Respond to New Password Challenge
```bash
aws cognito-idp admin-respond-to-auth-challenge   --user-pool-id <cognito_user_pool_id>   --client-id <cognito_client_id>   --challenge-name NEW_PASSWORD_REQUIRED   --challenge-responses 'NEW_PASSWORD=<new_secure_password>,USERNAME=admin'   --session "<session_value>"
```
- Replace `<new_secure_password>` with your desired secure password.  
- Replace `<session_value>` with the session returned from the previous step.

---

## 🧪 Testing API in Postman

1. Go to **Authorization → Bearer Token**  
2. Paste the **IdToken** (not AccessToken) received from Cognito authentication.  
3. Set the API URL, e.g.:
```
https://<api_id>.execute-api.<region>.amazonaws.com/<stage>/users
```
4. Send the request.  

✅ Valid JSON response is returned if:  
- User is in the correct Cognito group  
- IdToken is valid (~1 hour expiration)

---

## 📝 Notes

- Admin user is automatically added to the Admin group.  
- API Gateway method requests and integrations are dynamically generated from `endpoint_config`.  
- Integration type used is `HTTP_PROXY`.  
- Use an S3 backend in `backend.tf` for remote state management if required.  
- Update `admin_temp_password` in production to a secure value.

---

## 📌 Example Endpoint Configuration (`terraform.tfvars`)

```hcl
endpoint_config = {
  "/users" = {
    GET = { url = "https://jsonplaceholder.typicode.com/users", groups = ["Admin"] }
    POST = { url = "https://jsonplaceholder.typicode.com/users", groups = ["Admin"] }
  }
  "/users/{id}" = {
    GET    = { url = "https://jsonplaceholder.typicode.com/users/{id}", groups = ["Admin", "User"] }
    PUT    = { url = "https://jsonplaceholder.typicode.com/users/{id}", groups = ["Admin"] }
    DELETE = { url = "https://jsonplaceholder.typicode.com/users/{id}", groups = ["Admin"] }
  }
}
```

