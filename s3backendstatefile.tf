
# Replace the following placeholders with your actual values:

# your-aws-region: The AWS region where your resources are located.
# your-unique-bucket-name: The name of your S3 bucket.
# path/to/your/terraform.tfstate: The path within the S3 bucket where the state file will be stored.
# terraform-locks: The name of your DynamoDB table for state locking.

terraform {
  backend "s3" {
    bucket         = "your-unique-bucket-name"
    key            = "path/to/your/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "terraform-locks"
  }
}

resource "aws_s3_bucket" "example" {
  bucket = "example-bucket"
  acl    = "private"
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
