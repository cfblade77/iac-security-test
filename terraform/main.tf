# VULNERABLE - open S3 bucket, no encryption, hardcoded secret
provider "aws" {
  region     = "us-east-1"
  access_key = "AKIAIOSFODNN7EXAMPLE"
  secret_key = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
}

resource "aws_s3_bucket" "vulnerable_bucket" {
  bucket = "my-vulnerable-bucket"
  acl    = "public-read"
}

resource "aws_security_group" "vulnerable_sg" {
  name = "vulnerable-sg"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "vulnerable_db" {
  identifier        = "mydb"
  engine            = "mysql"
  instance_class    = "db.t3.micro"
  username          = "admin"
  password          = "supersecretpassword123"
  publicly_accessible = true
  storage_encrypted = false
}