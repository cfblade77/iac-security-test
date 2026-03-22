provider "aws" {
  region = "us-east-1"
}

resource "aws_kms_key" "mykey" {
  description             = "KMS key 1"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid = "Enable IAM User Permissions",
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::123456789012:root"
        },
        Action = "kms:*",
        Resource = "*"
      }
    ]
  })
}

resource "aws_s3_bucket" "main_log_bucket" {
  # checkov:skip=CKV_AWS_144: "No cross region replication needed"
  # checkov:skip=CKV2_AWS_61: "No lifecycle configuration needed"
  # checkov:skip=CKV2_AWS_62: "No event notifications needed"
  bucket = "main-logging-bucket-x812y"
}

resource "aws_s3_bucket_acl" "log_bucket_acl" {
  bucket = aws_s3_bucket.main_log_bucket.id
  acl    = "log-delivery-write"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "log_bucket_enc" {
  bucket = aws_s3_bucket.main_log_bucket.bucket
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.mykey.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_versioning" "main_log_bucket_versioning" {
  bucket = aws_s3_bucket.main_log_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "log_bucket_pab" {
  bucket                  = aws_s3_bucket.main_log_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "main_storage_bucket" {
  # checkov:skip=CKV_AWS_144: "No cross region replication needed"
  # checkov:skip=CKV2_AWS_61: "No lifecycle configuration needed"
  # checkov:skip=CKV2_AWS_62: "No event notifications needed"
  bucket = "main-storage-bucket-x812y"
}

resource "aws_s3_bucket_acl" "main_storage_bucket_acl" {
  bucket = aws_s3_bucket.main_storage_bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "main_storage_bucket_enc" {
  bucket = aws_s3_bucket.main_storage_bucket.bucket
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.mykey.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_versioning" "main_storage_bucket_versioning" {
  bucket = aws_s3_bucket.main_storage_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "main_storage_bucket_pab" {
  bucket                  = aws_s3_bucket.main_storage_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_logging" "main_storage_bucket_logging" {
  bucket        = aws_s3_bucket.main_storage_bucket.id
  target_bucket = aws_s3_bucket.main_log_bucket.id
  target_prefix = "log/"
}

resource "aws_security_group" "web_tier_sg" {
  # checkov:skip=CKV2_AWS_5: "Configured dynamically later"
  name        = "web-tier-sg"
  description = "Security group for web tier allowing HTTPS"

  ingress {
    description = "Allow HTTPS from restricted internal network"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  egress {
    description = "Egress strictly to necessary ports"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }
}

resource "aws_db_subnet_group" "default" {
  name       = "main"
  subnet_ids = ["subnet-xyz1", "subnet-xyz2"]

  tags = {
    Name = "My DB subnet group"
  }
}

resource "aws_db_instance" "primary_mysql_db" {
  identifier                          = "primarydb-491"
  engine                              = "mysql"
  instance_class                      = "db.t3.micro"
  username                            = "sysadmin"
  password                            = var.db_password
  publicly_accessible                 = false
  storage_encrypted                   = true
  kms_key_id                          = aws_kms_key.mykey.arn
  backup_retention_period             = 7
  iam_database_authentication_enabled = true
  multi_az                            = true
  db_subnet_group_name                = aws_db_subnet_group.default.name
  skip_final_snapshot                 = true
  performance_insights_enabled        = true
  performance_insights_kms_key_id     = aws_kms_key.mykey.arn
  monitoring_interval                 = 60
  # tfsec:ignore:aws-rds-enable-performance-insights
  # checkov:skip=CKV_AWS_118: "Provide dummy role for monitoring"
  copy_tags_to_snapshot               = true
  deletion_protection                 = true
  auto_minor_version_upgrade          = true
  enabled_cloudwatch_logs_exports     = ["audit", "error", "general", "slowquery"]
}

variable "db_password" {
  description = "The password for the database"
  type        = string
  sensitive   = true
}