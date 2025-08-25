# terraform {
#   backend "s3" {
#     bucket = "ritvik-rest-api-bucket"
#     key    = "terraform.tfstate"
#     region = "ap-south-1"
#   }
# }


# S3 - Backend

# resource "aws_s3_bucket" "mybucket" {
#   bucket = "ritvik-rest-api-bucket"

#   tags = {
#     Environment = "Dev"
#   }
# }