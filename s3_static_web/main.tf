# Configure Terraform to use AWS as the provider
terraform {
    # Specify the required providers and their versions
    required_providers {
        aws = {
            # Use the AWS provider from the HashiCorp registry
            source = "hashicorp/aws"
            # Specify the version of the AWS provider to use
            version = "~> 5.95"
        }
    }
}

# Define the AWS provider configuration
provider "aws" {
    # Specify the AWS region where resources will be created
    # Change this to the region where you want to deploy your resources
    region = "ap-south-2"
}

# Create a random string to use as a suffix for the bucket name
# This ensures the bucket name is unique and avoids name collisions
resource "random_string" "bucket_name_suffix" {
  length  = 8          # Length of the random string
  upper   = false      # Do not include uppercase letters
  special = false      # Do not include special characters
}

# Create an S3 bucket for hosting a static website
resource "aws_s3_bucket" "aws_s3_bucket_for_static_web" {
    # Define the bucket name with a unique suffix
    # Bucket names must be globally unique across all AWS accounts
    bucket = "bucket-for-static-web-${random_string.bucket_name_suffix.result}"    
    
    # Add tags to the bucket for identification and organization
    tags = {
        Name        = "Bucket-For-Static-Web-Hosting"  # Name tag for the bucket
        Environment = "Dev"                           # Environment tag (e.g., Dev, Prod)
    }

    # Automatically delete the bucket and its contents when the Terraform configuration is destroyed
    force_destroy = true
}

# Add website configuration to the S3 bucket
resource "aws_s3_bucket_website_configuration" "static_website" {
    # Reference the bucket created earlier
    bucket = aws_s3_bucket.aws_s3_bucket_for_static_web.id

    # Define the index document for the website
    # This is the default page that will be served when users visit the website
    index_document {
        suffix = "error.html"
    }

    # Define the error document for the website
    # This page will be displayed when an error occurs (e.g., 404 Not Found)
    error_document {
        key = "index.html"
    }
}

# Set bucket ownership and access controls
resource "aws_s3_bucket_ownership_controls" "bucket_ownership" {
    # Reference the bucket created earlier
    bucket = aws_s3_bucket.aws_s3_bucket_for_static_web.id

    # Define the ownership rule
    # "BucketOwnerPreferred" ensures that the bucket owner has full control over objects
    rule {
        object_ownership = "BucketOwnerPreferred"
    }
}

# Add block public access settings to the bucket
resource "aws_s3_bucket_public_access_block" "public_access_block" {
    # Reference the bucket created earlier
    bucket = aws_s3_bucket.aws_s3_bucket_for_static_web.id

    # Block public ACLs (Access Control Lists) for the bucket
    # Prevents the bucket from having public read/write permissions via ACLs
    block_public_acls = true

    # Ignore public ACLs for the bucket
    # Ensures that any public ACLs applied to the bucket are not honored
    ignore_public_acls = true

    # Allow public bucket policies
    # Setting this to false allows the bucket to have a public bucket policy
    block_public_policy = false

    # Do not restrict public bucket access
    # Setting this to false allows the bucket to be publicly accessible if a public bucket policy is applied
    restrict_public_buckets = false

    # Ensure this resource is created after the ownership controls are applied
    depends_on = [ aws_s3_bucket_ownership_controls.bucket_ownership ]
}

# Add a bucket policy to allow public access to the website
resource "aws_s3_bucket_policy" "bucket_policy" {
    # Reference the bucket created earlier
    bucket = aws_s3_bucket.aws_s3_bucket_for_static_web.id

    # Define the policy document for the bucket
    # This policy allows public read access to all objects in the bucket
    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow"                     # Allow the specified action
                Principal = "*"                      # Allow access from any user
                Action = "s3:GetObject"              # Allow the GetObject action (read access)
                Resource = "${aws_s3_bucket.aws_s3_bucket_for_static_web.arn}/*" # Apply to all objects in the bucket
            }
        ]
    })

    # Ensure this resource is created after the public access block settings are applied
    depends_on = [ aws_s3_bucket_public_access_block.public_access_block ]
}

# Upload the index.html file to the bucket
resource "aws_s3_object" "object" {
    # Reference the bucket created earlier
    bucket = aws_s3_bucket.aws_s3_bucket_for_static_web.bucket
    
    # Define the key (name) for the object in the bucket
    # This will be the name of the file in the bucket
    key    = "index.html"
    
    # Specify the source file to upload to the bucket
    # The file must exist in the specified path
    source = "${path.module}/web_src/index.html"

    # Calculate the MD5 hash of the file to ensure data integrity
    # The `filemd5` function computes the MD5 checksum of the specified file.
    # This ensures that the file uploaded to the S3 bucket matches the local file exactly.
    # If the file changes, the MD5 hash will also change, prompting Terraform to re-upload the file.
    etag = filemd5("${path.module}/web_src/index.html")
    
    # Set the content type for the uploaded object
    # This ensures the file is served with the correct MIME type
    content_type = "text/html"
}

# Upload the error.html file to the bucket
resource "aws_s3_object" "error_object" {
    # Reference the bucket created earlier
    bucket = aws_s3_bucket.aws_s3_bucket_for_static_web.bucket
    
    # Define the key (name) for the object in the bucket
    key    = "error.html"
    
    # Specify the source file to upload to the bucket
    # The file must exist in the specified path
    source = "${path.module}/web_src/error.html"

    # Calculate the MD5 hash of the file to ensure data integrity
    etag = filemd5("${path.module}/web_src/error.html")
    
    # Set the content type for the uploaded object
    # This ensures the file is served with the correct MIME type
    content_type = "text/html"
}

# Output the website URL
output "website_url" {
    # Construct the website URL using the bucket's website domain
    # This URL can be used to access the static website
    value = "http://${aws_s3_bucket_website_configuration.static_website.website_endpoint}"
}