# Terraform block to specify the required providers and their versions
terraform {
    # Define the required providers for this configuration
    required_providers {
        # Specify the AWS provider
        aws = {
            # Source of the provider, in this case, HashiCorp's AWS provider
            source = "hashicorp/aws"
            # Specify the version of the AWS provider to use
            version = "~> 5.96" # Use any version compatible with 5.96.x
        }
    }
}

# Provider block to configure the AWS provider
provider "aws" {
    # Specify the AWS region to use
    region = "ap-south-2"
}

# Resource block to create a random string for the S3 bucket name
resource "random_string" "bucket_name" {
    # Specify the length of the random string
    length  = 10
    # Specify the special characters to include in the random string
    special = false
    # Specify the upper case letters to not include in the random string
    upper   = false

    # Specify count to create multiple random strings
    count = 1
}

# Resource block to create an S3 bucket
resource "aws_s3_bucket" "restricted_bucket" {
    # Specify the bucket name using the random string created above
    bucket = "restricted-bucket-${random_string.bucket_name[0].result}"

    # Destroy the bucket if it is not empty
    force_destroy = true
  
}

# Resource block to block public access to the S3 bucket
resource "aws_s3_bucket_public_access_block" "restricted_bucket" {
    # Specify the bucket to apply the public access block to
    bucket = aws_s3_bucket.restricted_bucket.id

    # Disable blocking of public ACLs for this bucket
    block_public_acls       = false
    # Do not ignore public ACLs for this bucket
    ignore_public_acls      = false
    # Restrict public bucket policies for this bucket
    restrict_public_buckets = true
    # Disable blocking of public bucket policies for this bucket
    block_public_policy     = false
}

# Resource block to create an S3 bucket policy
resource "aws_s3_bucket_policy" "restricted_bucket" {
    # Specify the bucket to apply the policy to
    bucket = aws_s3_bucket.restricted_bucket.id

    # Define the policy document for the bucket
    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                # Specify the effect of the policy, in this case, allowing the action
                Effect = "Allow"
                
                # Define the principal(s) who are allowed to perform the action
                # To allow multiple IAM users, you can specify them as an array of ARNs
                # Example:
                # Principal = {
                #   AWS = [
                #     "arn:aws:iam::123456789012:user/User1",
                #     "arn:aws:iam::123456789012:user/User2"
                #   ]
                # }
                Principal = "*"

                # Specify the action(s) that are allowed
                Action = "s3:GetObject"

                # Specify the resource(s) the action applies to
                Resource = "${aws_s3_bucket.restricted_bucket.arn}/*"

                # Alternatively, if you want to allow access to all authenticated AWS users:
                # Principal = {
                #   AWS = "arn:aws:iam::aws:policy/AuthenticatedUsers"
                # }
            }
        ]
    })

    # Depend on the block public access resource to ensure it is created first
    depends_on = [aws_s3_bucket_public_access_block.restricted_bucket]
}
