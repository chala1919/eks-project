variable "namespace" {
  description = "Namespace for monitoring components"
  type        = string
  default     = "monitoring"
}

variable "kube_prometheus_stack_version" {
  description = "Version of the kube-prometheus-stack Helm chart"
  type        = string
  default     = null
}

variable "pushgateway_version" {
  description = "Version of the prometheus-pushgateway Helm chart"
  type        = string
  default     = null
}

variable "prometheus_retention" {
  description = "Prometheus data retention period"
  type        = string
  default     = "15d"
}

variable "prometheus_cpu_request" {
  description = "CPU request for Prometheus"
  type        = string
  default     = "500m"
}

variable "prometheus_memory_request" {
  description = "Memory request for Prometheus"
  type        = string
  default     = "1Gi"
}

variable "prometheus_cpu_limit" {
  description = "CPU limit for Prometheus"
  type        = string
  default     = "2000m"
}

variable "prometheus_memory_limit" {
  description = "Memory limit for Prometheus"
  type        = string
  default     = "1.5Gi"
}

variable "prometheus_storage_size" {
  description = "Storage size for Prometheus"
  type        = string
  default     = "50Gi"
}

variable "grafana_admin_user" {
  description = "Grafana admin username"
  type        = string
  default     = "admin"
}

variable "grafana_admin_password" {
  description = "Grafana admin password"
  type        = string
  sensitive   = true
  default     = "admin"
}

variable "grafana_storage_size" {
  description = "Storage size for Grafana"
  type        = string
  default     = "10Gi"
}

variable "alertmanager_enabled" {
  description = "Enable Alertmanager"
  type        = bool
  default     = true
}

variable "alertmanager_storage_size" {
  description = "Storage size for Alertmanager"
  type        = string
  default     = "10Gi"
}

variable "pushgateway_cpu_request" {
  description = "CPU request for Pushgateway"
  type        = string
  default     = "100m"
}

variable "pushgateway_memory_request" {
  description = "Memory request for Pushgateway"
  type        = string
  default     = "128Mi"
}

variable "pushgateway_cpu_limit" {
  description = "CPU limit for Pushgateway"
  type        = string
  default     = "200m"
}

variable "pushgateway_memory_limit" {
  description = "Memory limit for Pushgateway"
  type        = string
  default     = "256Mi"
}

variable "helm_depends_on" {
  description = "Helm release dependencies"
  type        = any
  default     = []
}

