variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_endpoint" {
  description = "Endpoint URL for the EKS cluster"
  type        = string
}

variable "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data for the EKS cluster"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs where Karpenter nodes will be launched"
  type        = list(string)
}

variable "node_security_group_id" {
  description = "Security group ID for EKS nodes"
  type        = string
}

variable "chart_version" {
  description = "Version of the Karpenter Helm chart"
  type        = string
  default     = null
}

variable "karpenter_version" {
  description = "Version of Karpenter to install"
  type        = string
  default     = "v0.37.0"
}

variable "spot_instance_types" {
  description = "List of EC2 instance types for spot instances"
  type        = list(string)
  default     = ["t3.small"]
}

variable "spot_capacity_type" {
  description = "EC2 capacity type for spot instances"
  type        = string
  default     = "spot"
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

