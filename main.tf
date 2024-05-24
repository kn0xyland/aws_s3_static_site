provider "aws" {
  region = var.awsregion
}

provider "aws" {
  region  = "us-east-1"
  alias   = "useast1"
}

locals {
  content_types = {
    ".html" : "text/html",
    ".css" : "text/css",
    ".js" : "text/javascript"
  }
}

module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 4.0"

  domain_name  = var.fqdn
  zone_id      = var.zoneid

  validation_method = "DNS"

  subject_alternative_names = [
    "*.${var.fqdn}"
  ]

  wait_for_validation = true

  providers = {
    aws = aws.useast1
  }

  tags = {
    Name = var.fqdn
  }
}

resource "aws_s3_bucket" "static_site_bucket" {
  bucket = var.static_bucket_name

  tags = var.default_tags

}

resource "aws_s3_bucket_server_side_encryption_configuration" "static_site_encryption_configuration" {
  bucket = aws_s3_bucket.static_site_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "static_site_bucket_versioning" {
  bucket = aws_s3_bucket.static_site_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket" "cloudfront_logging_bucket" {
  bucket = var.logging_bucket_name

  tags = var.default_tags
}

resource "aws_cloudfront_origin_access_identity" "cf_origin_access_identity" {
  comment = var.fqdn
}

resource "aws_s3_bucket_policy" "cloudfront_logging_bucket_policy" {
  bucket = aws_s3_bucket.cloudfront_logging_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "Allow CloudFront Logging"
        Effect    = "Allow"
        Principal = {
          AWS = [aws_cloudfront_origin_access_identity.cf_origin_access_identity.iam_arn]
        }
        Action = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudfront_logging_bucket.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      },
      {
        Sid       = "Allow CloudFront ListBucket"
        Effect    = "Allow"
        Principal = {
          AWS = [aws_cloudfront_origin_access_identity.cf_origin_access_identity.iam_arn]
        }
        Action = "s3:ListBucket"
        Resource = aws_s3_bucket.cloudfront_logging_bucket.arn
      }
    ]
  })
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logging_encryption_configuration" {
  bucket = aws_s3_bucket.cloudfront_logging_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "loggin_bucket_versioning" {
  bucket = aws_s3_bucket.cloudfront_logging_bucket.id

  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "logging_lifecycle" {
  bucket = aws_s3_bucket.static_site_bucket.id

  rule {
    id = "expire-logs"

    status = "Enabled"

    expiration {
      days = var.expire_days
    }

  }
}

resource "aws_s3_bucket_ownership_controls" "cloudfront_permissions" {
  bucket = aws_s3_bucket.cloudfront_logging_bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_ownership_controls" "static_permissions" {
  bucket = aws_s3_bucket.static_site_bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_policy" "static_site_bucket_policy_cloudfront_lockdown" {
  depends_on = [ aws_s3_bucket.static_site_bucket ]
  bucket = aws_s3_bucket.static_site_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "Allow CloudFront Logging"
        Effect    = "Allow"
        Principal = {
          AWS = [aws_cloudfront_origin_access_identity.cf_origin_access_identity.iam_arn]
        }
        Action = "s3:GetObject"
        Resource = "${aws_s3_bucket.static_site_bucket.arn}/*"
      },
      {
        Sid       = "Allow CloudFront ListBucket"
        Effect    = "Allow"
        Principal = {
          AWS = [aws_cloudfront_origin_access_identity.cf_origin_access_identity.iam_arn]
        }
        Action = "s3:ListBucket"
        Resource = aws_s3_bucket.static_site_bucket.arn
      }
    ]
  })
}

resource "aws_cloudfront_distribution" "static_site_distribution" {
  origin {
    domain_name = aws_s3_bucket.static_site_bucket.bucket_regional_domain_name
    origin_id   = aws_s3_bucket.static_site_bucket.id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.cf_origin_access_identity.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  aliases             = ["${var.fqdn}"]

  logging_config {
    bucket         = "${var.logging_bucket_name}.s3.amazonaws.com"
    include_cookies = false
    prefix         = "logs/"
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.static_site_bucket.id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = module.acm.acm_certificate_arn
    ssl_support_method  = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  retain_on_delete = true

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "www" {
  zone_id = var.zoneid
  name    = var.fqdn
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.static_site_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.static_site_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_s3_bucket_public_access_block" "public_access_block" {
  bucket = aws_s3_bucket.static_site_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "upload_object" {
  for_each      = fileset("html/", "*")
  bucket        = aws_s3_bucket.static_site_bucket.id
  key           = each.value
  source        = "html/${each.value}"
  etag          = filemd5("html/${each.value}")
  content_type  = "text/html"
}
