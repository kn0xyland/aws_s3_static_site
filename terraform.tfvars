## My Environment (Please update to suit your environment needs)
name_prefix        = "mytestsite"               # Name your deployment
awsregion          = "ap-southeast-2"       # Preferred AWS Region
aws_account_id     = "00000000000000"         # AWS Account ID
timezone           = "Australia/Sydney"     # Your Timezone

## Bucket Configuration

static_bucket_name  = "mytestsite.mydomain.io" # Name of the S3 Bucket
logging_bucket_name = "mytestsite-logging123"
expire_days         = "7"

# Route53 Configuration
zoneid             = "XXXXXXXXXXXXXXXXXXXXX"
fqdn               = "mytestsite.mydomain.io"

## Misc Variables
default_tags = {
  Project     = "s3 Static Site Hosting with CloudFront"
  Contact     = "youremail@gmail.com"
}