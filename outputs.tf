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

output "aurora_cluster_endpoint" {
  description = "The cluster endpoint for the Aurora DB"
  value       = aws_rds_cluster.primary.endpoint
}

output "aurora_reader_endpoint" {
  description = "The reader endpoint for the Aurora DB"
  value       = aws_rds_cluster.primary.reader_endpoint
}

output "aurora_port" {
  description = "The port for the Aurora DB"
  value       = aws_rds_cluster.primary.port
}

output "aurora_secondary_endpoint" {
  description = "The London region Aurora cluster endpoint"
  value       = aws_rds_cluster.secondary.endpoint
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

output "secondary_region" {
  description = "The secondary AWS region"
  value       = "eu-west-2" # London
}