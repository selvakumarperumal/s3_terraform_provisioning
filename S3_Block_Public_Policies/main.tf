terraform {
    # Specifies the required providers for this Terraform configuration.
    # In this case, we are using the AWS provider to interact with AWS resources.
    required_providers {
        aws = {
            # Specifies the source of the AWS provider. "hashicorp/aws" indicates
            # that the provider is maintained by HashiCorp and is available on the Terraform Registry.
            source  = "hashicorp/aws"
            
            # Specifies the version constraint for the AWS provider.
            # "~> 5.96" means any version >= 5.96.0 and < 6.0.0 is acceptable.
            version = "~> 5.96"
        }
    }  
}

# Specify Provider
provider "aws" {
    # Specifies the AWS region where resources will be created.
    region = "ap-south-2"
}

# Create random string for S3 bucket name
resource "random_string" "bucket_name" {
    # Specifies the length of the random string to be generated.
    length  = 10

    # Specifies the special characters to be included in the random string.
    special = false
    # Specifies the upper case letters to be not included in the random string.
    upper = false
    # Specifies the lower case letters to be included in the random string.
    lower = true

    # Specifies the number of random strings to generate.
    # In this case, we are generating only one random string.
    count   = 1
}

# Create S3 bucket
resource "aws_s3_bucket" "bucket" {
    # Specifies the name of the S3 bucket.
    # The name is generated using the random string created above.
    bucket = "public-policies-blocked-bucket-${random_string.bucket_name[0].result}"

    # destroy the bucket even if it is not empty
    force_destroy = true
}

#block public access
resource "aws_s3_bucket_public_access_block" "bucket" {
    # Specifies the S3 bucket to which the public access block configuration applies.
    bucket = aws_s3_bucket.bucket.id

    # Specifies whether to block public ACLs for the bucket.
    block_public_acls = false

    # Specifies whether to ignore public ACLs for the bucket.
    ignore_public_acls = false

    # Specifies whether to block public policy for the bucket.
    block_public_policy = true

    # Specifies whether to restrict public buckets.
    restrict_public_buckets = false
}

# Add a s3 bucket policy
resource "aws_s3_bucket_policy" "bucket" {
    # Specifies the S3 bucket to which the policy applies.
    bucket = aws_s3_bucket.bucket.id

    # Specifies the policy document in JSON format.
    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow"
                Principal = "*"
                Action = "s3:GetObject"
                Resource = "${aws_s3_bucket.bucket.arn}/*"
            }
        ]
    })
}

# Error: putting S3 Bucket Policy: operation error S3: PutBucketPolicy, 
# https response error StatusCode: 403, 
# api error AccessDenied: User is not authorized to perform: s3:PutBucketPolicy on resource 
# because public policies are blocked by the BlockPublicPolicy block public access setting.

# Solution:
# The error occurs because the S3 bucket has the `BlockPublicPolicy` setting enabled, which prevents public policies from being applied.
# To resolve this issue, update the `aws_s3_bucket_public_access_block` resource to set `block_public_policy` to `false`:

# resource "aws_s3_bucket_public_access_block" "bucket" {
#     bucket = aws_s3_bucket.bucket.id

#     block_public_acls       = false
#     ignore_public_acls      = false
#     block_public_policy     = true  # Change this to false
#     restrict_public_buckets = false
# }




