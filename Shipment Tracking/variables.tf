variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-south-1"
}

variable "dynamodb_table_name" {
  description = "DynamoDB table name for shipment trips"
  type        = string
  default     = "test-shipment-trips"
}

variable "dynamodb_partition_key" {
  description = "Partition key for DynamoDB table"
  type        = string
  default     = "shipmentId"
}

variable "dynamodb_sort_key" {
  description = "Sort key for DynamoDB table"
  type        = string
  default     = "timestamp"
}

variable "insert_lambda_name" {
  description = "Lambda function name for inserting shipment"
  type        = string
  default     = "InsertShipment"
}

variable "insert_lambda_file" {
  description = "Filename of InsertShipment Lambda"
  type        = string
  default     = "lambdas/insert_shipment.py"
}

variable "retrieve_lambda_name" {
  description = "Lambda function name for retrieving shipment"
  type        = string
  default     = "RetrieveShipment"
}

variable "retrieve_lambda_file" {
  description = "Filename of RetrieveShipment Lambda"
  type        = string
  default     = "lambdas/retrieve_shipment.py"
}

variable "max_locations" {
  description = "Maximum locations returned by RetrieveShipment Lambda"
  type        = number
  default     = 50
}

variable "rest_api_name" {
  description = "API Gateway REST API Name"
  type        = string
  default     = "ShipmentAPI"
}

variable "cognito_user_pool_name" {
  description = "Cognito User Pool name"
  type        = string
  default     = "Users"
}

variable "stage_name" {
  description = "API Gateway stage name"
  type        = string
  default     = "test"
}