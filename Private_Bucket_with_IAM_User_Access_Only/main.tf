# Configure Terraform to use the AWS provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.95"
    }
  }
}

# Configure the AWS provider
provider "aws" {
  region = "ap-south-2"
}

# Create random string for S3 bucket name
resource "random_string" "bucket_name" {
  length  = 10
  special = false
  upper = false
}

# Create an S3 bucket
resource "aws_s3_bucket" "private_bucket" {
  bucket = "private-bucket-${random_string.bucket_name.result}"
  force_destroy = true
}

# Enforce Bucket Owner Enforced setting
resource "aws_s3_bucket_ownership_controls" "bucket_ownership" {
  bucket = aws_s3_bucket.private_bucket.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# Block public access to the S3 bucket
resource "aws_s3_bucket_public_access_block" "private_bucket_public_access_block" {
  bucket = aws_s3_bucket.private_bucket.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true

  depends_on = [ aws_s3_bucket_ownership_controls.bucket_ownership ]
}

# Create IAM User
resource "aws_iam_user" "s3_user" {
  name = "s3-upload-user"
}

# Create IAM Policy for S3 access
resource "aws_iam_policy" "s3_access_policy" {
  name        = "S3AccessPolicy"
  description = "Policy to allow S3 access"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
        ]
        Resource = [
          aws_s3_bucket.private_bucket.arn,
          "${aws_s3_bucket.private_bucket.arn}/*"
        ]
      }
    ]
  })
}

# Attach the policy to the user
resource "aws_iam_user_policy_attachment" "s3_user_policy_attachment" {
  user       = aws_iam_user.s3_user.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}



