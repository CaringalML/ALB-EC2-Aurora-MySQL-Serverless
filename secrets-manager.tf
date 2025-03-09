# Random string generator for secret ID suffix
resource "random_string" "secrets_suffix" {
  length  = 6
  special = false
  upper   = false
}

# AWS Secrets Manager secret for database credentials
resource "aws_secretsmanager_secret" "aurora_credentials" {
  name        = "${var.project_name}-aurora-credentials-${random_string.secrets_suffix.result}"
  description = "Aurora MySQL credentials for ${var.project_name}"
  
  # Disable recovery window (no retention period when deleted)
  recovery_window_in_days = 0
  
  tags = {
    Name        = "${var.project_name}-aurora-credentials"
    Environment = var.environment
  }
}

# Store the database credentials in the secret
resource "aws_secretsmanager_secret_version" "aurora_credentials" {
  secret_id     = aws_secretsmanager_secret.aurora_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    engine   = "aurora-mysql"
    dbname   = var.db_name
  })
}

# Update the secret with connection details after the cluster is created
resource "aws_secretsmanager_secret_version" "aurora_credentials_update" {
  secret_id     = aws_secretsmanager_secret.aurora_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    engine   = "aurora-mysql"
    host     = aws_rds_cluster.primary.endpoint
    port     = aws_rds_cluster.primary.port
    dbname   = var.db_name
  })
  
  depends_on = [aws_rds_cluster.primary]
}

# Output the Secret ARN for reference
output "aurora_secret_arn" {
  description = "ARN of the Aurora database credentials secret"
  value       = aws_secretsmanager_secret.aurora_credentials.arn
}