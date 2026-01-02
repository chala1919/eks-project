variable "argocd_namespace" {
  description = "Namespace where ArgoCD is installed"
  type        = string
  default     = "argocd"
}

variable "namespace" {
  description = "Namespace where Dagster will be deployed"
  type        = string
  default     = "dagster"
}

variable "chart_version" {
  description = "Version of the Dagster Helm chart (leave null for latest)"
  type        = string
  default     = null
}

variable "argocd_helm_release" {
  description = "ArgoCD Helm release resource (for dependency)"
  type        = any
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "s3_bucket_name" {
  description = "S3 bucket name for storing pipeline results (auto-generated if null)"
  type        = string
  default     = null
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "alert_webhook_url" {
  description = "Webhook URL for Dagster job failure alerts (optional)"
  type        = string
  default     = null
}

variable "dagster_ui_url" {
  description = "URL for Dagster UI (for alert links)"
  type        = string
  default     = null
}

variable "cluster_pod_identity_agent_ready" {
  description = "Dependency to ensure Pod Identity agent is ready"
  type        = any
  default     = null
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

