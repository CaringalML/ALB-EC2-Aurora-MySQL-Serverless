# output "vpc_id" {
#   description = "The ID of the VPC"
#   value       = aws_vpc.main.id
# }

# output "public_subnets" {
#   description = "List of IDs of public subnets"
#   value       = aws_subnet.public[*].id
# }

# output "private_subnets" {
#   description = "List of IDs of private subnets"
#   value       = aws_subnet.private[*].id
# }

# output "alb_dns_name" {
#   description = "The DNS name of the load balancer"
#   value       = aws_lb.app.dns_name
# }

# output "alb_zone_id" {
#   description = "The canonical hosted zone ID of the load balancer"
#   value       = aws_lb.app.zone_id
# }

# output "certificate_arn" {
#   description = "The ARN of the certificate"
#   value       = aws_acm_certificate.cert.arn
# }

# output "aurora_cluster_endpoint" {
#   description = "The cluster endpoint for the Aurora DB"
#   value       = aws_rds_cluster.primary.endpoint
# }

# output "aurora_reader_endpoint" {
#   description = "The reader endpoint for the Aurora DB"
#   value       = aws_rds_cluster.primary.reader_endpoint
# }

# output "aurora_port" {
#   description = "The port for the Aurora DB"
#   value       = aws_rds_cluster.primary.port
# }



# output "web_acl_id" {
#   description = "The ID of the WAF Web ACL"
#   value       = aws_wafv2_web_acl.main.id
# }

# output "web_acl_arn" {
#   description = "The ARN of the WAF Web ACL"
#   value       = aws_wafv2_web_acl.main.arn
# }

# output "autoscaling_group_name" {
#   description = "The name of the Auto Scaling Group"
#   value       = aws_autoscaling_group.app.name
# }

# output "domain_name" {
#   description = "The domain name of the application"
#   value       = var.domain_name
# }

# output "cloudwatch_dashboard_url" {
#   description = "URL for the CloudWatch Dashboard"
#   value       = "https://${var.region}.console.aws.amazon.com/cloudwatch/home?region=${var.region}#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
# }

# output "primary_region" {
#   description = "The primary AWS region"
#   value       = var.region
# }



# output "launch_template_id" {
#   description = "The ID of the Launch Template used by ASG"
#   value       = aws_launch_template.app.id
# }

# output "ec2_role_arn" {
#   description = "ARN of the EC2 IAM Role"
#   value       = aws_iam_role.ec2_role.arn
# }

# output "ec2_instance_profile_name" {
#   description = "Name of the EC2 Instance Profile"
#   value       = aws_iam_instance_profile.ec2_profile.name
# }

# output "ecr_repository_url" {
#   description = "The URL of the ECR repository"
#   value       = aws_ecr_repository.app.repository_url
# }

# output "ecr_repository_name" {
#   description = "The name of the ECR repository"
#   value       = aws_ecr_repository.app.name
# }









output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = aws_subnet.private[*].id
}

output "alb_dns_name" {
  description = "The DNS name of the load balancer"
  value       = aws_lb.app.dns_name
}

output "alb_zone_id" {
  description = "The canonical hosted zone ID of the load balancer"
  value       = aws_lb.app.zone_id
}

output "certificate_arn" {
  description = "The ARN of the certificate"
  value       = aws_acm_certificate.cert.arn
}

# Replace Aurora outputs with MySQL outputs
output "mysql_primary_endpoint" {
  description = "The endpoint of the primary MySQL DB"
  value       = aws_db_instance.mysql.endpoint
}


output "mysql_port" {
  description = "The port for the MySQL DB"
  value       = aws_db_instance.mysql.port
}

output "web_acl_id" {
  description = "The ID of the WAF Web ACL"
  value       = aws_wafv2_web_acl.main.id
}

output "web_acl_arn" {
  description = "The ARN of the WAF Web ACL"
  value       = aws_wafv2_web_acl.main.arn
}

output "autoscaling_group_name" {
  description = "The name of the Auto Scaling Group"
  value       = aws_autoscaling_group.app.name
}

output "domain_name" {
  description = "The domain name of the application"
  value       = var.domain_name
}

output "cloudwatch_dashboard_url" {
  description = "URL for the CloudWatch Dashboard"
  value       = "https://${var.region}.console.aws.amazon.com/cloudwatch/home?region=${var.region}#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
}

output "primary_region" {
  description = "The primary AWS region"
  value       = var.region
}

output "launch_template_id" {
  description = "The ID of the Launch Template used by ASG"
  value       = aws_launch_template.app.id
}

output "ec2_role_arn" {
  description = "ARN of the EC2 IAM Role"
  value       = aws_iam_role.ec2_role.arn
}

output "ec2_instance_profile_name" {
  description = "Name of the EC2 Instance Profile"
  value       = aws_iam_instance_profile.ec2_profile.name
}

output "ecr_repository_url" {
  description = "The URL of the ECR repository"
  value       = aws_ecr_repository.app.repository_url
}

output "ecr_repository_name" {
  description = "The name of the ECR repository"
  value       = aws_ecr_repository.app.name
}

# Additional outputs for MySQL
output "mysql_resource_id" {
  description = "The RDS Resource ID of the MySQL instance"
  value       = aws_db_instance.mysql.resource_id
}

output "mysql_db_name" {
  description = "The database name"
  value       = aws_db_instance.mysql.db_name
}

output "mysql_kms_key_id" {
  description = "The ARN of the KMS key used for MySQL encryption"
  value       = aws_kms_key.rds.arn
}


# Add additional outputs
output "mysql_endpoint" {
  description = "The endpoint of the MySQL RDS instance"
  value       = aws_db_instance.mysql.endpoint
}

output "mysql_replica_endpoint" {
  description = "The endpoint of the MySQL RDS read replica"
  value       = aws_db_instance.mysql_replica.endpoint
}

output "mysql_arn" {
  description = "The ARN of the MySQL RDS instance"
  value       = aws_db_instance.mysql.arn
}

output "mysql_id" {
  description = "The ID of the MySQL RDS instance"
  value       = aws_db_instance.mysql.id
}