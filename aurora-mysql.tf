# resource "aws_db_subnet_group" "aurora" {
#   name       = "${var.project_name}-db-subnet-group"
#   subnet_ids = aws_subnet.private[*].id

#   tags = {
#     Name = "${var.project_name}-db-subnet-group"
#   }

#   lifecycle {
#     create_before_destroy = true
#   }
# }

# resource "aws_rds_cluster" "primary" {
#   cluster_identifier              = "${var.project_name}-aurora-cluster"
#   engine                          = "aurora-mysql"
#   engine_mode                     = "provisioned"
#   engine_version                  = "8.0.mysql_aurora.3.04.0"
#   database_name                   = var.db_name
#   master_username                 = var.db_username
#   master_password                 = var.db_password
#   backup_retention_period         = 7
#   preferred_backup_window         = "03:00-05:00"
#   preferred_maintenance_window    = "Sun:06:00-Sun:08:00"
#   db_subnet_group_name            = aws_db_subnet_group.aurora.name
#   vpc_security_group_ids          = [aws_security_group.aurora.id]
#   skip_final_snapshot             = true
#   storage_encrypted               = true
#   kms_key_id                      = aws_kms_key.primary_cluster_encryption.arn
#   apply_immediately               = true
#   deletion_protection             = false
#   db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.aurora.name

#   serverlessv2_scaling_configuration {
#     min_capacity = 0.5
#     max_capacity = 8.0
#   }

#   tags = {
#     Name = "${var.project_name}-aurora-cluster-primary"
#   }

#   lifecycle {
#     ignore_changes = [global_cluster_identifier]
#   }
# }

# resource "aws_kms_key" "primary_cluster_encryption" {
#   description             = "KMS key for primary Aurora cluster encryption"
#   deletion_window_in_days = 7
#   enable_key_rotation     = true

#   tags = {
#     Name = "${var.project_name}-primary-cluster-encryption-key"
#   }
# }

# resource "aws_rds_cluster_parameter_group" "aurora" {
#   name   = "${var.project_name}-aurora-cluster-pg"
#   family = "aurora-mysql8.0"

#   parameter {
#     name  = "character_set_server"
#     value = "utf8mb4"
#   }

#   parameter {
#     name  = "character_set_client"
#     value = "utf8mb4"
#   }

#   tags = {
#     Name = "${var.project_name}-aurora-cluster-pg"
#   }

#   lifecycle {
#     create_before_destroy = true
#   }
# }








# MySQL Parameter Group
resource "aws_db_parameter_group" "mysql" {
  name        = "${var.project_name}-mysql-params"
  family      = "mysql8.0"
  description = "MySQL parameter group for ${var.project_name}"

  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_client"
    value = "utf8mb4"
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-mysql-params"
    }
  )
}

# MySQL Option Group
resource "aws_db_option_group" "mysql" {
  name                 = "${var.project_name}-mysql-options"
  engine_name          = "mysql"
  major_engine_version = "8.0"

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-mysql-options"
    }
  )
}

# Subnet Group for MySQL
resource "aws_db_subnet_group" "mysql" {
  name        = "${var.project_name}-mysql-subnet-group"
  description = "MySQL DB subnet group for ${var.project_name}"
  subnet_ids  = aws_subnet.private[*].id

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-mysql-subnet-group"
    }
  )
}

# KMS Key for RDS Encryption
resource "aws_kms_key" "rds" {
  description             = "KMS key for RDS encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-rds-kms-key"
    }
  )
}

resource "aws_kms_alias" "rds" {
  name          = "alias/${var.project_name}-rds-key"
  target_key_id = aws_kms_key.rds.key_id
}

# CloudWatch Log Group for MySQL logs
resource "aws_cloudwatch_log_group" "mysql" {
  name              = "/aws/rds/mysql/${var.project_name}"
  retention_in_days = 30

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-mysql-logs"
    }
  )
}

# MySQL RDS Instance - Multi-AZ Deployment
resource "aws_db_instance" "mysql" {
  identifier             = "${var.project_name}-mysql"
  engine                 = "mysql"
  engine_version         = "8.0.33"
  instance_class         = "db.t3.small"
  allocated_storage      = 20
  max_allocated_storage  = 100
  storage_type           = "gp3"
  storage_encrypted      = true
  kms_key_id             = aws_kms_key.rds.arn
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  port                   = 3306
  publicly_accessible    = false
  vpc_security_group_ids = [aws_security_group.aurora.id]
  db_subnet_group_name   = aws_db_subnet_group.mysql.name
  parameter_group_name   = aws_db_parameter_group.mysql.name
  option_group_name      = aws_db_option_group.mysql.name
  
  # Multi-AZ configuration
  multi_az               = true
  
  # Backup and maintenance
  backup_retention_period   = var.backup_retention_period
  backup_window             = "03:00-05:00"  # UTC
  maintenance_window        = "Mon:00:00-Mon:03:00"  # UTC
  skip_final_snapshot       = !var.create_snapshot
  final_snapshot_identifier = var.create_snapshot ? "${var.project_name}-mysql-final-snapshot" : null
  deletion_protection       = var.enable_deletion_protection
  
  # Performance Insights - disabled for compatibility with t3.small
  performance_insights_enabled          = false
  
  # Enhanced Monitoring
  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.rds_monitoring_role.arn
  
  # Automated patching
  auto_minor_version_upgrade = true
  
  # Logs export
  enabled_cloudwatch_logs_exports = [
    "audit",
    "error",
    "general",
    "slowquery"
  ]
  
  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-mysql"
    }
  )

  depends_on = [aws_cloudwatch_log_group.mysql]
}

# IAM Role for RDS Enhanced Monitoring
resource "aws_iam_role" "rds_monitoring_role" {
  name = "${var.project_name}-rds-monitoring-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })
  
  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-rds-monitoring-role"
    }
  )
}

resource "aws_iam_role_policy_attachment" "rds_monitoring_attachment" {
  role       = aws_iam_role.rds_monitoring_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# Database Read Replica (for additional read capacity)
resource "aws_db_instance" "mysql_replica" {
  identifier             = "${var.project_name}-mysql-replica"
  replicate_source_db    = aws_db_instance.mysql.identifier
  instance_class         = "db.t3.small"
  publicly_accessible    = false
  vpc_security_group_ids = [aws_security_group.aurora.id]
  parameter_group_name   = aws_db_parameter_group.mysql.name
  
  # We don't need multi-AZ for the replica since the primary is already multi-AZ
  multi_az = false
  
  # Read replica specific settings
  backup_retention_period      = 0  # No automated backups for read replica
  skip_final_snapshot          = true
  deletion_protection          = var.enable_deletion_protection
  
  # Performance Insights for replica - disabled for compatibility with t3.small
  performance_insights_enabled          = false
  
  # Enhanced Monitoring
  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.rds_monitoring_role.arn
  
  # Automated patching
  auto_minor_version_upgrade = true
  
  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-mysql-replica"
    }
  )
}

