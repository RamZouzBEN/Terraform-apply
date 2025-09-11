variable "env" {
  type    = string
  default = "git-tst"
}

provider "aws" {
  region = "eu-west-1"
}

# 1) Seul le bucket (sans versioning/SSE/PAB ici)
resource "aws_s3_bucket" "tf_state" {
  bucket = "terraformstatetst" # mets EXACTEMENT le nom que tu utilises

  tags = {
    Name        = "terraform-state-${var.env}"
    Environment = var.env
  }

  lifecycle {
    prevent_destroy = true
  }
}

# 2) Versioning
resource "aws_s3_bucket_versioning" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# 3) SSE côté serveur
resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# 4) Public Access Block
resource "aws_s3_bucket_public_access_block" "tf_state" {
  bucket                  = aws_s3_bucket.tf_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 5) Table DynamoDB pour les locks
resource "aws_dynamodb_table" "tf_locks" {
  name         = "terraform-locks-TST" # EXACTEMENT le nom que tu utilises
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "terraform-locks-${var.env}"
    Environment = var.env
  }

  lifecycle {
    prevent_destroy = true
  }
}
