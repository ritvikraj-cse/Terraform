variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "api_name" {
  type    = string
  default = "MyAPI"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "methods" {
  type = list(string)
}
