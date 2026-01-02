variable "namespace" {
  description = "Namespace for ArgoCD"
  type        = string
  default     = "argocd"
}

variable "chart_version" {
  description = "Version of the ArgoCD Helm chart (leave null for latest)"
  type        = string
  default     = null
}

variable "hostname" {
  description = "Hostname for ArgoCD Ingress (optional for ALB)"
  type        = string
  default     = ""
}

variable "helm_depends_on" {
  description = "Dependencies for the Helm release"
  type        = any
  default     = null
}

