resource "aws_s3_bucket" "main" {
  bucket        = "${var.name}-documents-${local.account_id}"
  force_destroy = true
}

# Enhanced S3 security configuration available in AWS provider 6.14+
resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    id     = "cost_optimization"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

resource "aws_s3_bucket_intelligent_tiering_configuration" "main" {
  bucket = aws_s3_bucket.main.id
  name   = "EntireBucket"

  status = "Enabled"

  tiering {
    access_tier = "DEEP_ARCHIVE_ACCESS"
    days        = 180
  }
}

resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# bucket for storing llm logs
resource "aws_s3_bucket" "llm_logs" {
  bucket        = "${var.name}-llm-logs-${local.account_id}"
  force_destroy = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "llm_logs" {
  bucket = aws_s3_bucket.llm_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "llm_logs" {
  bucket = aws_s3_bucket.llm_logs.id

  rule {
    id     = "log_retention"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 60
      storage_class = "GLACIER"
    }

    expiration {
      days = 90
    }
  }
}
