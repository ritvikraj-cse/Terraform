variable "api_name" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "methods" {
  type = list(string)
}
