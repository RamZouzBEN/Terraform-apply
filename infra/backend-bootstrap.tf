resource "aws_s3_bucket" "tf_state" {
  bucket = "terraform-state-TST" # unique globalement
  acl    = "private"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = {
    Name        = "terraform-state-TST"
    Environment = TST
  }
}

resource "aws_dynamodb_table" "tf_locks" {
  name         = "terraform-locks-TST"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "terraform-locks-TST"
    Environment = TST
  }
}
