# 🚀 Terraform AWS ECS Fargate Deployment with Flask App

This repository provisions a **production-ready ECS Fargate infrastructure on AWS** using **Terraform** and deploys a sample **Flask application**.  
It demonstrates a full workflow:

1. **Run Flask app locally** for testing  
2. **Provision AWS infrastructure** with Terraform  
3. **Build & push Docker image** to ECR  
4. **Deploy app on ECS Fargate** behind an Application Load Balancer (ALB)  

---

## ⚙️ Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/downloads) `>=1.0`
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) configured with `aws configure`
- [Docker](https://docs.docker.com/get-docker/)
- [Python 3](https://www.python.org/downloads/) for running the sample Flask app locally

---

## 🖥️ Stage 0: Run the Flask App Locally

1. Install Python:
   ```bash
   brew install python
   python3 --version
   ```

2. Create and activate a virtual environment:
   ```bash
   cd /path/to/app
   python3 -m venv venv
   source venv/bin/activate
   ```

3. Install Flask:
   ```bash
   pip install Flask
   ```

4. Run the app:
   ```bash
   python app.py
   ```

5. Open in browser:
   ```
   http://localhost:3000
   http://localhost:3000/greet/YourName
   ```

---

## 🏗️ Stage 1: Infrastructure Creation (Terraform)

1. Initialize Terraform:
   ```bash
   terraform init
   ```

2. Review changes:
   ```bash
   terraform plan
   ```

3. Apply infrastructure:
   ```bash
   terraform apply -auto-approve
   ```

This creates:
- VPC, subnets, route tables, and endpoints  
- ECR repository  
- ECS cluster, task definition, and service  
- Application Load Balancer (ALB)  

---

## 📦 Stage 2: Build & Push Docker Image to ECR

1. Authenticate Docker with ECR:
   ```bash
   aws ecr get-login-password --region us-east-1 |    docker login --username AWS --password-stdin <account_id>.dkr.ecr.us-east-1.amazonaws.com
   ```

2. Build Docker image:
   ```bash
   docker build -t myapp .
   ```

3. Tag image:
   ```bash
   docker tag myapp:latest <account_id>.dkr.ecr.us-east-1.amazonaws.com/myapp:latest
   ```

4. Push image:
   ```bash
   docker push <account_id>.dkr.ecr.us-east-1.amazonaws.com/myapp:latest
   ```

---

## 🚀 Stage 3: ECS Deployment

1. Update ECS service with new image:
   ```bash
   aws ecs update-service      --cluster myapp-cluster      --service myapp-service      --force-new-deployment      --region us-east-1
   ```

2. Wait for ECS to deploy tasks.  

3. Test your app via ALB DNS (from Terraform outputs):
   ```text
   http://<alb-dns-name>
   ```

---

## 📊 Observability

- Logs → CloudWatch Logs (`/ecs/myapp`)  
- Metrics → ECS CPU/Memory in CloudWatch  
- Scaling → Auto scales between 2–5 tasks when CPU > 70%  

---

## 💰 Cost Optimization

- Fargate → Right-size vCPU/memory  
- EC2 → Use Spot or mixed instance types  
- ECR → Lifecycle policy keeps only last 5 images  

---

## 🌐 Accessing the App

Once deployed, visit the ALB DNS output:  
```text
http://<alb-dns-name>
```

Example:  
`http://myapp-alb-123456789.us-east-1.elb.amazonaws.com`

---

## 🛑 Cleanup

Destroy resources to avoid charges:
```bash
terraform destroy -auto-approve
```
