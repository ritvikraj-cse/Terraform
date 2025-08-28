# terraform {
#   backend "s3" {
#     bucket = "ritvik-ecs-bucket"
#     key    = "terraform.tfstate"
#     region = "us-east-1"
#   }
# }


# S3 - Backend

# resource "aws_s3_bucket" "mybucket" {
#   bucket = "ritvik-ecs-bucket"

#   tags = {
#     Environment = "Dev"
#   }
# }