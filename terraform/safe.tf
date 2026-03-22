# SAFE - encrypted, private, no hardcoded secrets
resource "aws_kms_key" "safe_key" {
  description             = "Safe KMS key"
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

resource "aws_s3_bucket" "safe_log_bucket" {
  # checkov:skip=CKV_AWS_144: "No cross region replication needed"
  # checkov:skip=CKV2_AWS_61: "No lifecycle configuration needed"
  # checkov:skip=CKV2_AWS_62: "No event notifications needed"
  bucket = "my-safe-log-bucket"
}

resource "aws_s3_bucket_acl" "safe_log_bucket_acl" {
  bucket = aws_s3_bucket.safe_log_bucket.id
  acl    = "log-delivery-write"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "safe_log_bucket_enc" {
  bucket = aws_s3_bucket.safe_log_bucket.bucket
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.safe_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_versioning" "safe_log_bucket_versioning" {
  bucket = aws_s3_bucket.safe_log_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "safe_log_bucket_pab" {
  bucket                  = aws_s3_bucket.safe_log_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "safe_bucket" {
  # checkov:skip=CKV_AWS_144: "No cross region replication needed"
  # checkov:skip=CKV2_AWS_61: "No lifecycle configuration needed"
  # checkov:skip=CKV2_AWS_62: "No event notifications needed"
  bucket = "my-safe-bucket"
}

resource "aws_s3_bucket_acl" "safe_bucket_acl" {
  bucket = aws_s3_bucket.safe_bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "safe_encryption" {
  bucket = aws_s3_bucket.safe_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.safe_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_versioning" "safe_bucket_versioning" {
  bucket = aws_s3_bucket.safe_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "safe_bucket_pab" {
  bucket                  = aws_s3_bucket.safe_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_logging" "safe_bucket_logging" {
  bucket        = aws_s3_bucket.safe_bucket.id
  target_bucket = aws_s3_bucket.safe_log_bucket.id
  target_prefix = "log/"
}

resource "aws_db_subnet_group" "safe_default" {
  name       = "safe-main"
  subnet_ids = ["subnet-abc1", "subnet-abc2"]

  tags = {
    Name = "My safe DB subnet group"
  }
}

resource "aws_db_instance" "safe_db" {
  identifier                          = "mydb-safe"
  engine                              = "mysql"
  engine_version                      = "8.0"
  instance_class                      = "db.t3.micro"
  username                            = var.db_username
  password                            = var.db_password
  publicly_accessible                 = false
  storage_encrypted                   = true
  kms_key_id                          = aws_kms_key.safe_key.arn
  backup_retention_period             = 7
  iam_database_authentication_enabled = true
  multi_az                            = true
  db_subnet_group_name                = aws_db_subnet_group.safe_default.name
  skip_final_snapshot                 = true
  performance_insights_enabled        = true
  performance_insights_kms_key_id     = aws_kms_key.safe_key.arn
  monitoring_interval                 = 60
  # checkov:skip=CKV_AWS_118: "Dummy role check"
  copy_tags_to_snapshot               = true
  deletion_protection                 = true
  auto_minor_version_upgrade          = true
  enabled_cloudwatch_logs_exports     = ["audit", "error", "general", "slowquery"]
}

variable "db_username" {
  type      = string
  sensitive = true
}

variable "db_password" {
  type      = string
  sensitive = true
}