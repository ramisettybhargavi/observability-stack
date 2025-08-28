  backend "s3" {
    bucket         = "observability-eks-tf-bucket"
    key            = "observability/terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    kms_key_id     = "arn:aws:kms:us-west-2:123456789012:key/abcd-efgh-ijkl"
    dynamodb_table = "terraform-state-lock"
    acl            = "bucket-owner-full-control"
  }
}

# S3 bucket for state
resource "aws_s3" "tf_state"{
    bucket="observability-eks-tf-bucket"

    lifecycle{
        prevent_destroy=false
    }
     tags = {
    Name        = "Terraform State Bucket"
    Environment = "production"
  }
}
resource "aws_s3_bucket_versioning" "terraform_state"{
      bucket= aws_s3.terraform_state.id
      versioning_configuration {
        status = enabled
      }
}
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
    bucket = aws_s3_.terraform_state.id
    rule {
      apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    }
  
}

# DynamoDB table for state locking
resource "aws_dynamodb_table" "tf_lock" {
  name         = "terraform-state-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "Terraform State Lock Table"
    Environment = "production"
  }
}

