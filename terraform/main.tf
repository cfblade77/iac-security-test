provider "aws" {
  region     = "us-east-1"
  access_key = "AKIAIOSFODNN7EXAMPLE"
  secret_key = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
}

resource "aws_s3_bucket" "main_storage_bucket" {
  bucket = "main-storage-bucket-x812y"
}

resource "aws_s3_bucket_acl" "main_storage_bucket_acl" {
  bucket = aws_s3_bucket.main_storage_bucket.id
  acl    = "public-read"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "main_storage_bucket_enc" {
  bucket = aws_s3_bucket.main_storage_bucket.bucket
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_security_group" "web_tier_sg" {
  name = "web-tier-sg"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "primary_mysql_db" {
  identifier          = "primarydb-491"
  engine              = "mysql"
  instance_class      = "db.t3.micro"
  username            = "sysadmin"
  password            = "Hardc0dedP@ssw0rd!"
  publicly_accessible = true
  storage_encrypted   = false
}

variable "db_password" {
  description = "The password for the database"
  type        = string
  sensitive   = true
}