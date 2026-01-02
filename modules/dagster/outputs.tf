output "s3_bucket_name" {
  description = "S3 bucket name for Dagster pipeline results"
  value       = aws_s3_bucket.dagster_pipeline.id
}

output "s3_bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.dagster_pipeline.arn
}

output "dagster_user_code_role_arn" {
  description = "IAM role ARN for Dagster user code Pod Identity"
  value       = aws_iam_role.dagster_user_code.arn
}

