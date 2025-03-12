# Database subnet group
resource "aws_db_subnet_group" "aurora" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

# Primary AWS region (Sydney) Aurora Serverless v2 cluster
resource "aws_rds_cluster" "primary" {
  cluster_identifier              = "${var.project_name}-aurora-cluster"
  engine                          = "aurora-mysql"
  engine_mode                     = "provisioned"
  engine_version                  = "8.0.mysql_aurora.3.04.0"
  database_name                   = var.db_name
  master_username                 = var.db_username
  master_password                 = var.db_password
  backup_retention_period         = 7
  preferred_backup_window         = "03:00-05:00"
  preferred_maintenance_window    = "Sun:06:00-Sun:08:00"
  db_subnet_group_name            = aws_db_subnet_group.aurora.name
  vpc_security_group_ids          = [aws_security_group.aurora.id]
  skip_final_snapshot             = var.create_snapshot ? false : true
  final_snapshot_identifier       = var.create_snapshot ? "${var.project_name}-final-snapshot-${formatdate("YYYYMMDDHHmmss", timestamp())}" : null
  storage_encrypted               = true
  kms_key_id                      = aws_kms_key.primary_cluster_encryption.arn
  apply_immediately               = true
  deletion_protection             = false
  global_cluster_identifier       = aws_rds_global_cluster.global.id
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.aurora.name

  serverlessv2_scaling_configuration {
    min_capacity = 0.5
    max_capacity = 8.0
  }

  tags = {
    Name = "${var.project_name}-aurora-cluster-primary"
  }
}


# Create KMS key for primary region cluster encryption
resource "aws_kms_key" "primary_cluster_encryption" {
  description             = "KMS key for primary Aurora cluster encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  
  tags = {
    Name = "${var.project_name}-primary-cluster-encryption-key"
  }
}

# Create KMS key for the secondary region
resource "aws_kms_key" "secondary_cluster_encryption" {
  provider                = aws.london
  description             = "KMS key for secondary Aurora cluster encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  
  tags = {
    Name = "${var.project_name}-secondary-cluster-encryption-key"
  }
}

# Secondary AWS region (London) Aurora Serverless v2 cluster
resource "aws_rds_cluster" "secondary" {
  provider                        = aws.london
  cluster_identifier              = "${var.project_name}-aurora-cluster-london"
  engine                          = "aurora-mysql"
  engine_mode                     = "provisioned"
  engine_version                  = "8.0.mysql_aurora.3.04.0"
  db_subnet_group_name            = aws_db_subnet_group.aurora_london.name
  vpc_security_group_ids          = [aws_security_group.aurora_london.id]
  skip_final_snapshot             = true
  storage_encrypted               = true
  kms_key_id                      = aws_kms_key.secondary_cluster_encryption.arn
  apply_immediately               = true
  global_cluster_identifier       = aws_rds_global_cluster.global.id
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.aurora_london.name
  
  # No master credentials for secondary region
  depends_on = [aws_rds_cluster.primary]
  
  serverlessv2_scaling_configuration {
    min_capacity = 0.5
    max_capacity = 8.0
  }

  tags = {
    Name = "${var.project_name}-aurora-cluster-secondary"
  }
}

# Global cluster that spans both regions
resource "aws_rds_global_cluster" "global" {
  global_cluster_identifier = "${var.project_name}-global-db"
  engine                    = "aurora-mysql"
  engine_version            = "8.0.mysql_aurora.3.04.0"
  storage_encrypted         = true
}

# Primary cluster - serverless instance
resource "aws_rds_cluster_instance" "primary" {
  count                           = 2 # 1 writer + 1 reader
  identifier                      = "${var.project_name}-aurora-instance-${count.index}"
  cluster_identifier              = aws_rds_cluster.primary.id
  instance_class                  = "db.serverless"
  engine                          = aws_rds_cluster.primary.engine
  engine_version                  = aws_rds_cluster.primary.engine_version
  db_parameter_group_name         = aws_db_parameter_group.aurora.name
  auto_minor_version_upgrade      = true
  performance_insights_enabled    = true
  performance_insights_kms_key_id = aws_kms_key.pi.arn
  performance_insights_retention_period = 7 # 7 days

  tags = {
    Name = "${var.project_name}-aurora-instance-${count.index}"
  }
}

# Secondary cluster - serverless instances (read replicas)
resource "aws_rds_cluster_instance" "secondary" {
  provider                        = aws.london
  count                           = 2 # read replicas only
  identifier                      = "${var.project_name}-aurora-london-instance-${count.index}"
  cluster_identifier              = aws_rds_cluster.secondary.id
  instance_class                  = "db.serverless"
  engine                          = aws_rds_cluster.secondary.engine
  engine_version                  = aws_rds_cluster.secondary.engine_version
  db_parameter_group_name         = aws_db_parameter_group.aurora_london.name
  auto_minor_version_upgrade      = true
  performance_insights_enabled    = true
  performance_insights_kms_key_id = aws_kms_key.pi_london.arn
  performance_insights_retention_period = 7 # 7 days

  tags = {
    Name = "${var.project_name}-aurora-london-instance-${count.index}"
  }
}

# Cluster parameter group
resource "aws_rds_cluster_parameter_group" "aurora" {
  name   = "${var.project_name}-aurora-cluster-pg"
  family = "aurora-mysql8.0"

  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_client"
    value = "utf8mb4"
  }

  tags = {
    Name = "${var.project_name}-aurora-cluster-pg"
  }
}

# London region database subnet group
resource "aws_db_subnet_group" "aurora_london" {
  provider   = aws.london
  name       = "${var.project_name}-db-subnet-group-london"
  subnet_ids = aws_subnet.london_private[*].id

  tags = {
    Name = "${var.project_name}-db-subnet-group-london"
  }
}

# London VPC and subnets (simplified for brevity)
resource "aws_vpc" "london" {
  provider   = aws.london
  cidr_block = var.london_vpc_cidr

  tags = {
    Name = "${var.project_name}-vpc-london"
  }
}

resource "aws_subnet" "london_public" {
  provider          = aws.london
  count             = 2
  vpc_id            = aws_vpc.london.id
  cidr_block        = cidrsubnet(var.london_vpc_cidr, 8, count.index)
  availability_zone = data.aws_availability_zones.london.names[count.index]

  tags = {
    Name = "${var.project_name}-public-subnet-london-${count.index + 1}"
  }
}

resource "aws_subnet" "london_private" {
  provider          = aws.london
  count             = 2
  vpc_id            = aws_vpc.london.id
  cidr_block        = cidrsubnet(var.london_vpc_cidr, 8, count.index + 2)
  availability_zone = data.aws_availability_zones.london.names[count.index]

  tags = {
    Name = "${var.project_name}-private-subnet-london-${count.index + 1}"
  }
}

data "aws_availability_zones" "london" {
  provider = aws.london
  state    = "available"
}

# London region security group
resource "aws_security_group" "aurora_london" {
  provider    = aws.london
  name        = "${var.project_name}-aurora-sg-london"
  description = "Security group for Aurora MySQL in London"
  vpc_id      = aws_vpc.london.id

  ingress {
    description = "MySQL"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.london_vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-aurora-sg-london"
  }
}

# London region DB parameter group
resource "aws_db_parameter_group" "aurora_london" {
  provider = aws.london
  name     = "${var.project_name}-aurora-db-pg-london"
  family   = "aurora-mysql8.0"

  tags = {
    Name = "${var.project_name}-aurora-db-pg-london"
  }
}

# London region cluster parameter group
resource "aws_rds_cluster_parameter_group" "aurora_london" {
  provider = aws.london
  name     = "${var.project_name}-aurora-cluster-pg-london"
  family   = "aurora-mysql8.0"

  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_client"
    value = "utf8mb4"
  }

  tags = {
    Name = "${var.project_name}-aurora-cluster-pg-london"
  }
}

# KMS key for Performance Insights - Sydney
resource "aws_kms_key" "pi" {
  description             = "KMS key for Performance Insights"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name = "${var.project_name}-pi-kms-key"
  }
}

# KMS key for Performance Insights - London
resource "aws_kms_key" "pi_london" {
  provider                = aws.london
  description             = "KMS key for Performance Insights in London"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name = "${var.project_name}-pi-kms-key-london"
  }
}

# DB parameter group - Sydney
resource "aws_db_parameter_group" "aurora" {
  name   = "${var.project_name}-aurora-db-pg"
  family = "aurora-mysql8.0"

  tags = {
    Name = "${var.project_name}-aurora-db-pg"
  }
}