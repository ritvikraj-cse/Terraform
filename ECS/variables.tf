variable "region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "repo_name" {
  description = "ECR repository name"
  type        = string
  default     = "rit-app-repo"
}
