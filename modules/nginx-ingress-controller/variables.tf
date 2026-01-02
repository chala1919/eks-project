variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the EKS cluster is deployed"
  type        = string
}

variable "node_security_group_id" {
  description = "Security group ID of the EKS nodes"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for the ALB"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs (not used for ALB, kept for compatibility)"
  type        = list(string)
  default     = []
}

variable "namespace" {
  description = "Namespace for NGINX Ingress Controller"
  type        = string
  default     = "ingress-nginx"
}

variable "chart_version" {
  description = "Version of the NGINX Ingress Controller Helm chart (leave null for latest)"
  type        = string
  default     = null
}

variable "alb_scheme" {
  description = "Scheme for the ALB (internet-facing or internal)"
  type        = string
  default     = "internet-facing"
}

variable "replica_count" {
  description = "Number of NGINX Ingress Controller replicas"
  type        = number
  default     = 2
}

variable "resource_requests_cpu" {
  description = "CPU request for NGINX Ingress Controller pods"
  type        = string
  default     = "100m"
}

variable "resource_requests_memory" {
  description = "Memory request for NGINX Ingress Controller pods"
  type        = string
  default     = "90Mi"
}

variable "resource_limits_cpu" {
  description = "CPU limit for NGINX Ingress Controller pods"
  type        = string
  default     = "500m"
}

variable "resource_limits_memory" {
  description = "Memory limit for NGINX Ingress Controller pods"
  type        = string
  default     = "512Mi"
}

variable "helm_depends_on" {
  description = "Dependencies for the Helm release"
  type        = any
  default     = null
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
