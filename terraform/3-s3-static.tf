resource "aws_s3_bucket" "static_website" {
  bucket = "${var.project_name}-static-site-${random_id.bucket_suffix.hex}"
  depends_on = [ aws_s3_bucket.code_bucket ]

}

resource "aws_s3_bucket_website_configuration" "static_website_config" {
  bucket = aws_s3_bucket.static_website.id
  index_document {
    suffix = "index.html" 
  }
}

resource "aws_s3_bucket_public_access_block" "static_bucket_pab" {
  bucket = aws_s3_bucket.static_website.id

  block_public_acls       = true
  block_public_policy     = false
  ignore_public_acls      = true
  restrict_public_buckets = false
}

resource "aws_cloudfront_origin_access_control" "static_website_oac" {
  name                              = "${var.project_name}-static-website-oac"
  description                       = "OAC for ${var.project_name} static website"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "static_website_distribution" {
  origin {
    domain_name              = aws_s3_bucket.static_website.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.static_website_oac.id
    origin_id                = "S3-${aws_s3_bucket.static_website.bucket}"
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${var.project_name} static website distribution"
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.static_website.bucket}"

    cache_policy_id = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad" 

    viewer_protocol_policy = "redirect-to-https"
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Name = "${var.project_name}-cloudfront-distribution"
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}


resource "aws_s3_bucket_policy" "static_website_policy" {
  bucket = aws_s3_bucket.static_website.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontServicePrincipal"
        Effect    = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.static_website.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.static_website_distribution.arn
          }
        }
      }
    ]
  })

  depends_on = [
    aws_s3_bucket_public_access_block.static_bucket_pab
  ]
}


data "template_file" "index_html" {
  template = file("../index.html.tpl")

  vars = {
    cognito_user_pool_client_id = aws_cognito_user_pool_client.main.id
    cognito_user_pool_domain    = aws_cognito_user_pool_domain.main.domain
    aws_region                  = var.aws_region
    website_url                 = aws_cloudfront_distribution.static_website_distribution.domain_name
  }
}

resource "aws_s3_object" "index_html" {
  bucket       = aws_s3_bucket.static_website.bucket
  key          = "index.html"
  content      = data.template_file.index_html.rendered
  content_type = "text/html"
}
data "template_file" "home_html" {
  template = file("../home.html.tpl")

  vars = {
    COGNITO_USER_POOL_CLIENT_ID = aws_cognito_user_pool_client.main.id
    COGNITO_USER_POOL_DOMAIN    = aws_cognito_user_pool_domain.main.domain
    AWS_REGION                  = var.aws_region
    WEBSITE_URL                 = aws_cloudfront_distribution.static_website_distribution.domain_name
    API_URL                     = "https://${aws_api_gateway_rest_api.api.id}.execute-api.${var.aws_region}.amazonaws.com/${aws_api_gateway_stage.api_stage.stage_name}"
  }
}


resource "aws_s3_object" "home_html" {
  bucket       = aws_s3_bucket.static_website.bucket
  key          = "home.html"
  content      = data.template_file.home_html.rendered
  content_type = "text/html"
}



# If you need the CloudFront URL as well
output "website_url" {
  value = "https://${aws_cloudfront_distribution.static_website_distribution.domain_name}"
}
