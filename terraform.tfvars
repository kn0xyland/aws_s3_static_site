## My Environment (Please update to suit your environment needs)
name_prefix        = "mysite"               # Name your deployment
awsregion          = "ap-southeast-2"       # Preferred AWS Region
aws_account_id     = "123456789012"         # AWS Account ID
timezone           = "Australia/Sydney"     # Your Timezone

## Bucket Configuration

static_bucket_name  = "your.domain.here" # Name of the S3 Bucket
logging_bucket_name = "mysite-logging"
expire_days         = "7"

# Route53 Configuration
zoneid             = "XXXXXXXXXXXXXXXXXXXX"
fqdn               = "your.domain.here"

## Misc Variables
default_tags = {
  Project     = "s3 Static Site Hosting with CloudFront"
  Contact     = "youremail@gmail.com"
}