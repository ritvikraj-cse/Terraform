
# 🚀 AWS API Gateway (Mock REST API with IAM Auth)

This project provisions an **AWS API Gateway** REST API with **IAM authentication**, supporting **path params**, **query params**, and **headers**.  
It also sets up an **IAM user with API access keys** to invoke the API.  

---

## 📂 Features
- REST API Gateway with mock integration
- Resource: `/users/{user_id}`
- Supports:
  - Path parameters (`{user_id}`)
  - Query parameters (`?qp=test`)
  - Headers (`H-Test`)
- IAM authentication for secure access
- Custom response headers
- Deployment + stage (`dev`)
- IAM user with API access keys for invocation

---

## ⚙️ Setup Instructions

### 1️⃣ Clone Repo
```bash
git clone https://github.com/ritvikraj-cse/Terraform.git
cd Terraform/apigateway-iam-mock
```

### 2️⃣ Initialize Terraform
```bash
terraform init
```

### 3️⃣ Review Execution Plan
```bash
terraform plan
```

### 4️⃣ Apply Changes
```bash
terraform apply -auto-approve
```

---

## 📤 Terraform Outputs

After apply, fetch the outputs:
```bash
terraform output api_invoke_url
terraform output api_user_access_key
terraform output api_user_secret_key
```

Example:
```hcl
api_invoke_url      = "https://d80zzhx5m5.execute-api.ap-south-1.amazonaws.com/dev/users/{user_id}"
api_user_access_key = "<YOUR_ACCESS_KEY>"
api_user_secret_key = "<YOUR_SECRET_KEY>"

```

---

## 🧪 Testing the API

### Using Postman

- **Method**: `GET` (or `POST/PUT` depending on `var.methods`)  
- **URL**:
  ```
  https://d80zzhx5m5.execute-api.ap-south-1.amazonaws.com/dev/users/123?qp=test
  ```
- **Headers**:
  ```
  H-Test: demo
  ```
- **Authorization**:
  - Type: **AWS Signature**
  - AccessKey: `<api_user_access_k>`
  - SecretKey: `<api_user_secret_k>`
  - AWS Region: `ap-south-1`
  - Service Name: `execute-api`

---


### ✅ Expected Response
```json
{
  "message": "GET success",
  "pathParam": "123",
  "queryParam": "test",
  "headerParam": "demo",
  "body": {}
}
```

---

## 🛡 Security Notes
- API secured with **IAM authentication**
- Only users with attached IAM policy (`execute-api:Invoke`) can invoke
- Access keys are Terraform-managed → store securely

---

## 🔮 Future Enhancements
- [ ] Enable **CloudWatch logging & metrics**
- [ ] Add **CORS support** (`OPTIONS` method)
- [ ] Configure **Usage Plans & API Keys**
- [ ] Add **X-Ray tracing**
- [ ] Support **multiple environments** (`dev`, `staging`, `prod`)

