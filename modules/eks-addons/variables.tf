variable "cluster_id" {
  description = "ID of the EKS cluster (for dependencies)"
  type        = string
}

variable "node_security_group_id" {
  description = "Security group ID for EKS nodes"
  type        = string
}
