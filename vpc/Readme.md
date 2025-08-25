
# 🌐 AWS VPC + ALB + Bastion + ASG

![Terraform](https://img.shields.io/badge/Terraform-v1.5+-blue?logo=terraform)
![AWS](https://img.shields.io/badge/AWS-Cloud-orange?logo=amazon-aws)

**Deploy a highly available AWS production setup with:**  
- VPC (Public + Private Subnets across 2 AZs)  
- Bastion Host (SSH access)  
- Application Load Balancer (ALB)  
- Auto Scaling Group (ASG) with Launch Template  
- NAT Gateways for private subnets  
- Security Groups for ALB, Web, and Bastion  

---

## 🏗️ Architecture

![AWS VPC Architecture](https://github.com/ritvikraj-cse/Terraform/blob/75dcf7a18564795070ec857e2679c40582875147/vpc/VPC.png)

- **Public Subnets** → Bastion, ALB, NAT  
- **Private Subnets** → ASG Web/App Servers  
- **SG Rules** → ALB → 8080, Bastion → 22  

---

## ⚡ Quick Start

### 1️⃣ Clone the repo
```bash
git clone <repo-url>
cd <repo-folder>
```

### 2️⃣ Update Terraform variables
```hcl
region          = "ap-south-1"
public_key_path = "~/.ssh/id_rsa.pub"
bastion_ip      = "YOUR_PUBLIC_IP/32"
```

### 3️⃣ Initialize Terraform
```bash
terraform init
```

### 4️⃣ Preview & Apply
```bash
terraform plan
terraform apply -auto-approve
```

---

## 🔑 Access

- **Bastion Host:** SSH to `bastion_ip`  
- **Application Load Balancer:** Open `loadbalancerdns` in browser  

---

## 📊 Outputs

| Output             | Description                        |
|-------------------|------------------------------------|
| `vpc_id`           | VPC ID                             |
| `loadbalancerdns`  | ALB DNS Name                        |
| `bastion_ip`       | Public IP of Bastion Host           |

---

## 🧩 Notes

- High availability across **2 Availability Zones**  
- Auto Scaling Group adjusts instance count based on demand  
- Use Terraform **remote backend** for state management in production  
- Ensure your SSH key exists at `public_key_path` before deployment  


