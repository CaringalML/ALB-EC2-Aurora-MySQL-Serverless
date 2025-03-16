variable "region" {
  description = "The AWS region to deploy resources"
  type        = string
  default     = "ap-southeast-1" # Singapore
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

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
  default     = "artisantiling.co.nz"
}

# VPC Configuration
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}



# EC2 Configuration
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

# Database Configuration
variable "db_name" {
  description = "Name of the database"
  type        = string
  default     = "mydb"
}

variable "db_username" {
  description = "Username for the database"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Password for the database"
  type        = string
  sensitive   = true
}

# Autoscaling Configuration
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

# Security and Compliance
variable "enable_deletion_protection" {
  description = "Whether to enable deletion protection on resources"
  type        = bool
  default     = false  # Enable in production
}

variable "waf_rate_limit" {
  description = "Rate limit for WAF (requests per 5 minutes)"
  type        = number
  default     = 2000
}

# Load Balancer Configuration
variable "alb_access_logs_enabled" {
  description = "Whether to enable access logs for the ALB"
  type        = bool
  default     = true
}

variable "ssl_policy" {
  description = "SSL policy for the ALB HTTPS listener"
  type        = string
  default     = "ELBSecurityPolicy-2016-08"
}

# Aurora Configuration
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

variable "create_snapshot" {
  description = "Whether to create a final snapshot before deletion"
  type        = bool
  default     = false  # Make this true if you want to have a final snapshot
}

# ECR Configuration
variable "ecr_repository_name" {
  description = "Name of the ECR repository"
  type        = string
  default     = "my-api"
}

# Common Tags
variable "common_tags" {
  description = "Common tags to be applied to all resources"
  type        = map(string)
  default = {
    Project     = "ArtisanTiling"
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}
