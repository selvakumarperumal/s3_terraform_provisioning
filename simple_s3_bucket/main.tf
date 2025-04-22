# Configure the AWS provider
# This specifies the AWS region where the resources will be created.
provider "aws" {
    region = "ap-south-2"
}

# Create a random string resource
# This generates a random string that will be appended to the S3 bucket name to ensure uniqueness.
resource "random_string" "bucket_name_string" {
    length          = 8          # Length of the random string
    special         = false      # Do not include special characters
    upper           = false      # Do not include uppercase letters
    lower           = true       # Include lowercase letters
    min_upper       = 0          # Minimum number of uppercase letters (not used here)
    min_special     = 0          # Minimum number of special characters (not used here)
    min_lower       = 0          # Minimum number of lowercase letters (not enforced here)
    override_special = "_"       # Overrides special characters (not used here)
    keepers = {
        # Ensures a new string is generated if the "name" value changes
        name = "simple_bucket_name"
    }
}

# Create an S3 bucket
# This defines an S3 bucket with a unique name by appending the random string.
resource "aws_s3_bucket" "bucket" {
    bucket = "simple-bucket-by-selva-${random_string.bucket_name_string.result}" # Unique bucket name

    tags = {
        Name        = "simple-bucket" # Tag for identifying the bucket
        Environment = "dev"           # Tag for specifying the environment
    }
}


###

# # Configure the bucket's ACL (Access Control List)
# # This sets the bucket's access control to "private", ensuring it is not publicly accessible.
# resource "aws_s3_bucket_acl" "bucket_acl" {
#     bucket = aws_s3_bucket.bucket.id # Reference to the bucket ID
#     acl    = "private"               # Access control set to private
# }

# AWS recently introduced the Object Ownership = Bucket owner enforced feature, which completely disables ACLs for the bucket.

# If your bucket was created with this setting (ObjectOwnership = BucketOwnerEnforced), then trying to set ACLs (like private, public-read) will fail.
# If you want to set ACLs, you need to remove the Object Ownership setting from the bucket.

###


# Enable versioning on the S3 bucket
# This allows multiple versions of an object to be stored in the bucket.
resource "aws_s3_bucket_versioning" "bucket_versioning" {
    bucket = aws_s3_bucket.bucket.id # Reference to the bucket ID

    versioning_configuration {
        status = "Enabled" # Enables versioning
    }
}

# Configure public access block settings
# This blocks all public access to the bucket, ensuring it is secure.
resource "aws_s3_bucket_public_access_block" "bucket_public_access_block" {
    bucket = aws_s3_bucket.bucket.id # Reference to the bucket ID

    block_public_acls       = true  # Blocks public ACLs
    ignore_public_acls      = true  # Ignores public ACLs
    block_public_policy     = false  # Blocks public bucket policies
    restrict_public_buckets = true  # Restricts public bucket access
}

# Define a bucket policy
# This policy allows public read access to objects in the bucket.
resource "aws_s3_bucket_policy" "bucket_policy" {
    bucket = aws_s3_bucket.bucket.id # Reference to the bucket ID

    policy = jsonencode({
        Version = "2012-10-17" # Policy version
        Statement = [
            {
                Effect = "Allow"                # Allow access
                Principal = "*"                 # Applies to all users
                Action = "s3:GetObject"         # Allows reading objects
                Resource = "${aws_s3_bucket.bucket.arn}/*" # Applies to all objects in the bucket
            }
        ]
    })
}