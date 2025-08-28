provider "aws" {
    region= "us-west-2"
}

resource "aws_s3" "terraform_state"{
    bucket="eks_bucket_for_testing_using_terraform"

    lifecycle{
        prevent_destroy=false
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
resource "aws_dyanamodb" "dynamodb_s3" {
    name= "aws_s3_locks"
    billing_mode="PAY_PER_REQUEST"
    hash_key = "LOCKID"
    attribute{
        name= "LOCKID"
        type="S"
    }
  
}