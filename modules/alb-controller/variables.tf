variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  type        = string
}

variable "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the EKS cluster is deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs (used for AWS Load Balancer Controller configuration)"
  type        = list(string)
  default     = []
}

variable "controller_version" {
  description = "Version of the AWS Load Balancer Controller Helm chart (leave null for latest)"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
