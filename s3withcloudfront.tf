
# Create the S3 buckets
resource "aws_s3_bucket" "s301" {
  bucket = "s301"
  acl    = "private"
}

resource "aws_s3_bucket" "s302" {
  bucket = "s302"
  acl    = "private"
}

resource "aws_s3_bucket" "s303" {
  bucket = "s303"
  acl    = "private"
}

# Create the IAM roles for the CloudFront distributions
resource "aws_iam_role" "cloudfront_role" {
  name = "cloudfront-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudfront.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy" "cloudfront_policy" {
  name = "cloudfront-policy"
  role = aws_iam_role.cloudfront_role.name

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject"
      ],
      "Resource": [
        "${aws_s3_bucket.s301.arn}/*",
        "${aws_s3_bucket.s302.arn}/*",
        "${aws_s3_bucket.s303.arn}/*"
      ]
    }
  ]
}
POLICY
}

# Create the CloudFront distributions
resource "aws_cloudfront_distribution" "cf01" {
  origin {
    domain_name = aws_s3_bucket.s301.bucket_regional_domain_name
    origin_id   = "s301"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  origin {
    domain_name = "example.com" # Replace with your auth service domain
    origin_id   = "auth"
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "s301"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 300
    max_ttl                = 1200
  }

  custom_error_response {
    error_caching_min_ttl = 0
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
  }

  aliases = ["cf01.example.com"]

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["US", "CA", "GB", "DE"]
    }
  }

  tags = {
    Environment = "production"
  }
}

resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "My CloudFront OAI"
  
}

resource "aws_cloudwatch_log_group" "log_group01" {
  name              = "/aws/cloudfront/cf01"
  retention_in_days = 30
  tags = {
        Environment = "QA"
        Project     = "qa_cloudfront1"
    }
}


# resource "aws_cloudfront_distribution" "cf02" {
#   # Similar configuration as CF01
# }

# resource "aws_cloudfront_distribution" "cf03" {
#   # Similar configuration as CF01
# }

