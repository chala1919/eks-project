resource "aws_s3_bucket" "dagster_pipeline" {
  bucket = var.s3_bucket_name != null ? var.s3_bucket_name : "${var.name_prefix}-dagster-pipeline-${var.cluster_name}"

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-dagster-pipeline-bucket"
    }
  )
}

resource "aws_s3_bucket_public_access_block" "dagster_pipeline" {
  bucket = aws_s3_bucket.dagster_pipeline.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "dagster_pipeline" {
  bucket = aws_s3_bucket.dagster_pipeline.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "dagster_pipeline" {
  bucket = aws_s3_bucket.dagster_pipeline.id

  versioning_configuration {
    status = "Enabled"
  }
}

