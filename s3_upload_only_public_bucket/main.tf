# Configure Terraform to use the AWS provider
terraform {
    required_providers {
        aws = {
            source  = "hashicorp/aws" # Specifies the AWS provider source
            version = "~> 5.95"       # Specifies the version of the AWS provider to use
        }
    }
}

# Configure the AWS provider
provider "aws" {
    region = "us-east-1" # Specifies the AWS region where resources will be created
}

# Create a random string to append to the S3 bucket name
resource "random_string" "bucket_name" {
    length  = 10          # Length of the random string
    upper   = false       # Exclude uppercase letters
    special = false       # Exclude special characters
    count   = 1           # Generate one random string
}

# Create an S3 bucket with a unique name
resource "aws_s3_bucket" "my_bucket" {
    bucket        = "upload-only-bucket-${random_string.bucket_name[0].result}" # Bucket name with random string appended
    force_destroy = true # Allows the bucket to be forcibly deleted even if it contains objects
}

# Bucket Owner Enforcement
resource "aws_s3_bucket_ownership_controls" "my_bucket_ownership_controls" {
    bucket = aws_s3_bucket.my_bucket.id # Reference to the S3 bucket

    # Define ownership controls for the bucket
    rule {
        object_ownership = "BucketOwnerEnforced" # Enforce ownership by the bucket owner
    }
}

# Configure public access settings for the S3 bucket
resource "aws_s3_bucket_public_access_block" "my_bucket_public_access_block" {
    bucket = aws_s3_bucket.my_bucket.id # Reference to the S3 bucket

    # Allow public access by disabling all public access block settings
    block_public_acls       = false # Do not block public ACLs
    ignore_public_acls      = false # Do not ignore public ACLs
    block_public_policy     = false # Do not block public bucket policies
    restrict_public_buckets = false # Do not restrict public bucket access
}

# Create an S3 bucket policy to allow public access for uploading objects
resource "aws_s3_bucket_policy" "my_bucket_policy" {
    bucket = aws_s3_bucket.my_bucket.id # Reference to the S3 bucket

    # Define the bucket policy in JSON format
    policy = jsonencode({
        Version = "2012-10-17" # Policy version
        Statement = [
            {
                Effect = "Allow" # Allow the specified actions
                Principal = "*"  # Allow access from any user
                Action = "s3:PutObject" # Allow uploading objects to the bucket
                Resource = "${aws_s3_bucket.my_bucket.arn}/*" # Apply the policy to all objects in the bucket
            },
            # {
            #     Effect = "Allow" # Allow the specified actions
            #     Principal = "*"  # Allow access from any user
            #     Action = "s3:GetObject" # Allow reading objects from the bucket
            #     Resource = "${aws_s3_bucket.my_bucket.arn}/*" # Apply the policy to all objects in the bucket
            # }
        ]
    })
}
