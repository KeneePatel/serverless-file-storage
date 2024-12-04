variable "aws_region" {
  description = "AWS region for all resources"
  default     = "us-east-1"
}

variable "project_name" {
  description = "Base name for project resources"
  default     = "file-storage-system"
}

variable "tags" {
  description = "Tags to set on all resources"
  default     = {
    Project     = "File Storage System"
    Environment = "Dev"
    ManagedBy   = "Terraform"
  }
}

variable "environment" {
  description = "Deployment environment"
  default     = "dev"
}
