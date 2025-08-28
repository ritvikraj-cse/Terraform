variable "vpc_id" {
  type = string
}

variable "private_subnets" {
  type = list(string)
}

variable "public_subnets" {
  type = list(string)
}

variable "repo_url" {
  type = string
}

variable "region" {
  type = string
}

variable "app_name" {
  type = string
}
