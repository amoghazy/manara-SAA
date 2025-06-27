
resource "random_id" "bucket_suffix" {
  byte_length = 9
}

resource "aws_s3_bucket" "source_bucket" {
  bucket = "${var.project_name}-${random_id.bucket_suffix.hex}"
}

resource "aws_s3_bucket" "destination_bucket" {
  bucket = "${aws_s3_bucket.source_bucket.bucket}-resized"
  depends_on = [ aws_s3_bucket.source_bucket ]
}

resource "aws_s3_bucket_versioning" "source_versioning" {
  bucket = aws_s3_bucket.source_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
  depends_on = [ aws_s3_bucket.source_bucket ]
}

resource "aws_s3_bucket_versioning" "destination_versioning" {
  bucket = aws_s3_bucket.destination_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
  depends_on = [ aws_s3_bucket.destination_bucket ]
}

resource "aws_s3_bucket_public_access_block" "source_bucket_pab" {
  bucket = aws_s3_bucket.source_bucket.id

  block_public_acls       = true
  block_public_policy     = false
  ignore_public_acls      = true
  restrict_public_buckets = false
  depends_on = [ aws_s3_bucket.source_bucket ]
}

resource "aws_s3_bucket_public_access_block" "destination_bucket_pab" {
  bucket = aws_s3_bucket.destination_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
  depends_on = [ aws_s3_bucket.destination_bucket ]

}

resource "aws_s3_bucket_policy" "destination_bucket_policy" {
  bucket = aws_s3_bucket.destination_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.destination_bucket.arn}/*"
      }
    ]
  })
}

resource "aws_s3_bucket" "code_bucket" {
  bucket = "${var.project_name}-${random_id.bucket_suffix.hex}-codepy"
  depends_on = [ aws_s3_bucket.destination_bucket ]
}

resource "aws_s3_bucket_versioning" "code_versioning" {
  bucket = aws_s3_bucket.code_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
  depends_on = [ aws_s3_bucket.code_bucket ]
}

resource "aws_s3_bucket_public_access_block" "code_bucket_pab" {
  bucket = aws_s3_bucket.code_bucket.id

  block_public_acls       = true
  block_public_policy     = false
  ignore_public_acls      = true
  restrict_public_buckets = false
  depends_on = [ aws_s3_bucket.code_bucket ]

}
resource "aws_s3_object" "lambda_zip" {
  bucket = aws_s3_bucket.code_bucket.bucket
  key    = "lambda_function.zip"
  source = "lambda_function.zip"
  depends_on = [ aws_s3_bucket.code_bucket ]

}