# Configure the AWS provider with the specified region
provider "aws" {
    region = "ap-south-2"
}

# Create a random suffix for the bucket name
resource "random_string" "bucket_suffix" {
    length  = 8
    special = false
    upper = false
    lower = true
}

# Create an S3 bucket with a unique name
resource "aws_s3_bucket" "public_bucket" {
    bucket = "selvas-public-bucket-${random_string.bucket_suffix.result}"
    force_destroy = true
}

# remolve public access block
resource "aws_s3_bucket_public_access_block" "public_access_block" {
    bucket = aws_s3_bucket.public_bucket.id
  
    block_public_acls       = false
    ignore_public_acls      = false
    block_public_policy     = false
    restrict_public_buckets = false
}

# Create S3 bucket policy to allow public read access
resource "aws_s3_bucket_policy" "public_policy" {
    bucket = aws_s3_bucket.public_bucket.id
  
    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow"
                Principal = "*"
                Action = "s3:GetObject"
                Resource = "${aws_s3_bucket.public_bucket.arn}/*"
            }
        ]
    })

    depends_on = [ aws_s3_bucket_public_access_block.public_access_block ]
}

