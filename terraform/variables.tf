# variables.tf
variable "aws_region" {
  type    = string
  default = "us-east-1"

}

variable "project_name" {
  type    = string
  default = "serverless-image-processing"


}

variable "environment" {
  type    = string
  default = "dev"

}

variable "lambda_timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 60


}

variable "lambda_memory_size" {
  description = "Lambda function memory size in MB"
  type        = number
  default     = 512

}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 14

}

variable "enable_api_gateway" {
  description = "Whether to create API Gateway resources"
  type        = bool
  default     = true
}

variable "enable_dynamodb" {
  description = "Whether to create DynamoDB table for metadata"
  type        = bool
  default     = true
}

variable "supported_image_formats" {
  description = "List of supported image file extensions"
  type        = list(string)
  default     = ["jpg", "jpeg", "png", "gif", "bmp", "webp"]
}

variable "upload_prefix" {
  description = "S3 prefix for uploaded images"
  type        = string
  default     = "uploads/"

  validation {
    condition     = can(regex("^[a-zA-Z0-9/._-]*/$", var.upload_prefix))
    error_message = "Upload prefix must end with a forward slash and contain only valid S3 key characters."
  }
}

variable "processed_prefix" {
  description = "S3 prefix for processed images"
  type        = string
  default     = "processed/"


}

variable "enable_versioning" {
  description = "Enable S3 bucket versioning"
  type        = bool
  default     = true
}

variable "enable_encryption" {
  description = "Enable S3 bucket encryption"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "ServerlessImageProcessing"
    Terraform   = "true"
    Environment = "dev"
  }
}