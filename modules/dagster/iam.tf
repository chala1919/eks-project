resource "aws_iam_role" "dagster_user_code" {
  name = "${var.name_prefix}-dagster-user-code-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "pods.eks.amazonaws.com"
        }
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "dagster_user_code_s3" {
  name = "${var.name_prefix}-dagster-user-code-s3-policy"
  role = aws_iam_role.dagster_user_code.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::*",
          aws_s3_bucket.dagster_pipeline.arn,
          "${aws_s3_bucket.dagster_pipeline.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_eks_pod_identity_association" "dagster_user_code" {
  cluster_name    = var.cluster_name
  namespace       = var.namespace
  service_account = "dagster-user-code"
  role_arn        = aws_iam_role.dagster_user_code.arn

  depends_on = [
    var.cluster_pod_identity_agent_ready,
  ]
}

resource "aws_eks_pod_identity_association" "dagster_user_deployments" {
  cluster_name    = var.cluster_name
  namespace       = var.namespace
  service_account = "dagster-dagster-user-deployments-user-deployments"
  role_arn        = aws_iam_role.dagster_user_code.arn

  depends_on = [
    var.cluster_pod_identity_agent_ready,
  ]
}

