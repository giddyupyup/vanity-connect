data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "web_app" {
  bucket = "${var.project_name}-${data.aws_caller_identity.current.account_id}-${var.aws_region}-web"
}

resource "aws_s3_bucket_public_access_block" "web_app" {
  bucket = aws_s3_bucket.web_app.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "web_app" {
  bucket = aws_s3_bucket.web_app.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "web_app" {
  bucket = aws_s3_bucket.web_app.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_object" "web_runtime_config" {
  bucket       = aws_s3_bucket.web_app.id
  key          = "runtime-config.json"
  content_type = "application/json"
  content = jsonencode({
    callersApiUrl = var.callers_api_url
  })
}

resource "aws_cloudfront_origin_access_control" "web_app" {
  name                              = "${var.project_name}-web-oac"
  description                       = "CloudFront OAC for vanity web app S3 origin"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "web_app" {
  enabled             = true
  default_root_object = "index.html"
  price_class         = "PriceClass_100"

  origin {
    domain_name              = aws_s3_bucket.web_app.bucket_regional_domain_name
    origin_id                = "web-app-s3-origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.web_app.id
  }

  default_cache_behavior {
    target_origin_id       = "web-app-s3-origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

  ordered_cache_behavior {
    path_pattern           = "runtime-config.json"
    target_origin_id       = "web-app-s3-origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 1

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

  custom_error_response {
    error_caching_min_ttl = 0
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
  }

  custom_error_response {
    error_caching_min_ttl = 0
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

resource "aws_s3_bucket_policy" "web_app" {
  bucket = aws_s3_bucket.web_app.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontReadOnly"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action = ["s3:GetObject"]
        Resource = [
          "${aws_s3_bucket.web_app.arn}/*"
        ]
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.web_app.arn
          }
        }
      }
    ]
  })
}
