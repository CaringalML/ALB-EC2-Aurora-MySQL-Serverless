variable "region" {
  description = "The AWS region to deploy resources"
  type        = string
  default     = "ap-southeast-2" # Sydney
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "artisan-tiling"
}

variable "environment" {
  description = "Environment (production, staging, development)"
  type        = string
  default     = "production"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "london_vpc_cidr" {
  description = "CIDR block for the London VPC"
  type        = string
  default     = "10.1.0.0/16"
}

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
  default     = "artisantiling.co.nz"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "db_name" {
  description = "Name of the database"
  type        = string
  default     = "artisantiling"
}

variable "db_username" {
  description = "Username for the database"
  type        = string
  sensitive   = true
  # Do not set a default value for sensitive variables
}

variable "db_password" {
  description = "Password for the database"
  type        = string
  sensitive   = true
  # Do not set a default value for sensitive variables
}

variable "common_tags" {
  description = "Common tags to be applied to all resources"
  type        = map(string)
  default = {
    Project     = "ArtisanTiling"
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}

variable "waf_rate_limit" {
  description = "Rate limit for WAF (requests per 5 minutes)"
  type        = number
  default     = 2000
}

variable "alb_access_logs_enabled" {
  description = "Whether to enable access logs for the ALB"
  type        = bool
  default     = true
}

variable "aurora_min_capacity" {
  description = "Minimum capacity units for Aurora Serverless"
  type        = number
  default     = 0.5
}

variable "aurora_max_capacity" {
  description = "Maximum capacity units for Aurora Serverless"
  type        = number
  default     = 8.0
}

variable "backup_retention_period" {
  description = "Number of days to retain database backups"
  type        = number
  default     = 7
}

variable "enable_deletion_protection" {
  description = "Whether to enable deletion protection on resources"
  type        = bool
  default     = true
}

variable "asg_min_size" {
  description = "Minimum size of the Auto Scaling Group"
  type        = number
  default     = 2
}

variable "asg_max_size" {
  description = "Maximum size of the Auto Scaling Group"
  type        = number
  default     = 10
}

variable "asg_desired_capacity" {
  description = "Desired capacity of the Auto Scaling Group"
  type        = number
  default     = 4
}

variable "ssl_policy" {
  description = "SSL policy for the ALB HTTPS listener"
  type        = string
  default     = "ELBSecurityPolicy-2016-08"
}