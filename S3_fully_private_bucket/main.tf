# Configure the Terraform AWS provider
terraform {
    required_providers {
        aws = {
            # Specify the AWS provider source and version
            source  = "hashicorp/aws"
            version = "~> 5.96" # Use AWS provider version 5.96 or compatible versions
        }
    }
}

# Define the AWS provider configuration
provider "aws" {
    # Specify the AWS region where resources will be created
    region = "ap-south-2" # Example: Asia Pacific (Hyderabad)
}

# Generate a random string to ensure the bucket name is unique
resource "random_string" "bucket_suffix" {
    length  = 8          # Length of the random string
    special = false      # Exclude special characters
    upper   = false      # Exclude uppercase letters
    lower   = true       # Include lowercase letters
}

# Create an S3 bucket with a unique name
resource "aws_s3_bucket" "Complete_private_bucket" {
    # Define the bucket name using the random string suffix
    bucket = "selvas-private-bucket-${random_string.bucket_suffix.result}"
    
    # Allow Terraform to delete the bucket even if it contains objects
    force_destroy = true
}

# Configure the S3 bucket to block all public access
resource "aws_s3_bucket_public_access_block" "Complete_private_bucket" {
    # Reference the S3 bucket created above
    bucket = aws_s3_bucket.Complete_private_bucket.id

    # Enable settings to block all public access to the bucket
    block_public_acls       = true  # Block public ACLs
    ignore_public_acls      = true  # Ignore public ACLs
    block_public_policy     = true  # Block public bucket policies
    restrict_public_buckets = true  # Restrict public bucket access
}
