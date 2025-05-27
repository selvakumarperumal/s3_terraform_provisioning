# Configure Terraform to use the AWS provider
terraform {
    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "~> 5.96"
        }
    }
}

# Configure the AWS provider
provider "aws" {
    region = "ap-south-2"
}

# Create a random string to append to the bucket name for uniqueness
resource "random_string" "bucket_name" {
    length  = 10
    special = false
    upper   = false
    lower   = true
}

# Create an S3 bucket with a unique name
resource "aws_s3_bucket" "bucket" {
    bucket        = "block-public-acls-${random_string.bucket_name.result}"
    force_destroy = true
}

# Define object ownership for the bucket
resource "aws_s3_bucket_ownership_controls" "bucket_ownership" {
    bucket = aws_s3_bucket.bucket.id

    rule {
        object_ownership = "BucketOwnerPreferred"
    }
}

# Block public access settings for the bucket
resource "aws_s3_bucket_public_access_block" "block_public_acls" {
    bucket = aws_s3_bucket.bucket.id

    # Block public ACLs for the bucket
    block_public_acls       = true
    # Allow public ACLs to be ignored (set to false to enforce stricter rules)
    ignore_public_acls      = false
    # Do not block public bucket policies
    block_public_policy     = false
    # Do not restrict public bucket access
    restrict_public_buckets = false

    # Ensure this resource is created after ownership controls are applied
    depends_on = [aws_s3_bucket_ownership_controls.bucket_ownership]
}

# The difference between block_public_acls and ignore_public_acls lies in how they handle public ACLs (Access Control Lists) for the S3 bucket:

# block_public_acls:

# When set to true, this explicitly blocks the creation of new public ACLs on the bucket.
# It ensures that no public ACLs can be added to the bucket, effectively preventing any public access via ACLs.
# ignore_public_acls:

# When set to false, it enforces stricter rules by ensuring that existing public ACLs are not ignored. This means any existing public ACLs will still be evaluated and could allow public access if they are not blocked.
# When set to true, it allows the bucket to ignore any existing public ACLs. This can be useful if you want to ensure public ACLs are not considered, regardless of their configuration.
# Key Difference:
# block_public_acls prevents the creation of new public ACLs.
# ignore_public_acls determines whether existing public ACLs are considered or ignored.
# In your configuration:

# block_public_acls = true: Blocks new public ACLs.
# ignore_public_acls = false: Ensures existing public ACLs are not ignored, enforcing stricter access control.

# The following resource attempts to set a public-read ACL on the bucket.
# However, this conflicts with the BlockPublicAcls setting applied above,
# which prevents public ACLs from being set. This will result in an AccessDenied error.
# Commenting out this resource to avoid the error.

# resource "aws_s3_bucket_acl" "bucket_acl" {
#   bucket = aws_s3_bucket.bucket.id
#   acl    = "public-read"
#
#   # Ensure this resource is created after the public access block settings are applied
#   depends_on = [aws_s3_bucket_public_access_block.block_public_acls]
# }

# Note: If you need to allow public access to the bucket, you must disable the
# BlockPublicAcls setting in the aws_s3_bucket_public_access_block resource.
# Alternatively, you can remove the aws_s3_bucket_acl resource if public access is not required.
