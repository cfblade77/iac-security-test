# SAFE - encrypted, private, no hardcoded secrets
resource "aws_s3_bucket" "safe_bucket" {
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
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_db_instance" "safe_db" {
  identifier        = "mydb-safe"
  engine            = "mysql"
  instance_class    = "db.t3.micro"
  username          = var.db_username
  password          = var.db_password
  publicly_accessible = false
  storage_encrypted = true
}