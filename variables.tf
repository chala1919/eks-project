variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "eks-cluster"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "my-eks-cluster"
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster (leave null for latest available version)"
  type        = string
  default     = null
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones for subnets"
  type        = list(string)
  default     = null
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (2 subnets)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (2 subnets)"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "node_group_desired_size" {
  description = "Desired number of nodes in the node group"
  type        = number
  default     = 2
}

variable "node_group_max_size" {
  description = "Maximum number of nodes in the node group"
  type        = number
  default     = 10
}

variable "node_group_min_size" {
  description = "Minimum number of nodes in the node group"
  type        = number
  default     = 1
}

variable "enabled_cluster_log_types" {
  description = "List of control plane logging types to enable"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 7
}

variable "addon_vpc_cni_version" {
  description = "Version of the VPC CNI add-on (leave null for latest compatible version)"
  type        = string
  default     = null
}

variable "addon_kube_proxy_version" {
  description = "Version of the kube-proxy add-on (leave null for latest compatible version)"
  type        = string
  default     = null
}

variable "addon_coredns_version" {
  description = "Version of the CoreDNS add-on (leave null for latest compatible version)"
  type        = string
  default     = null
}

variable "addon_eks_pod_identity_agent_version" {
  description = "Version of the eks-pod-identity-agent add-on (leave null for latest compatible version)"
  type        = string
  default     = null
}

variable "addon_ebs_csi_version" {
  description = "Version of the EBS CSI driver add-on (leave null for latest compatible version)"
  type        = string
  default     = null
}

variable "addon_node_monitoring_agent_version" {
  description = "Version of the EKS node monitoring agent add-on (leave null for latest compatible version)"
  type        = string
  default     = null
}

variable "alb_controller_version" {
  description = "Version of the AWS Load Balancer Controller Helm chart (leave null for latest)"
  type        = string
  default     = null
}

variable "nginx_ingress_chart_version" {
  description = "Version of the NGINX Ingress Controller Helm chart (leave null for latest)"
  type        = string
  default     = null
}

variable "argocd_chart_version" {
  description = "Version of the ArgoCD Helm chart (leave null for latest)"
  type        = string
  default     = "9.0.1"
}

variable "karpenter_chart_version" {
  description = "Version of the Karpenter Helm chart (leave null for latest)"
  type        = string
  default     = null
}

variable "dagster_chart_version" {
  description = "Version of the Dagster Helm chart (leave null for latest)"
  type        = string
  default     = null
}

variable "kube_prometheus_stack_version" {
  description = "Version of the kube-prometheus-stack Helm chart (leave null for latest)"
  type        = string
  default     = null
}

variable "pushgateway_version" {
  description = "Version of the prometheus-pushgateway Helm chart (leave null for latest)"
  type        = string
  default     = null
}

variable "grafana_admin_password" {
  description = "Grafana admin password"
  type        = string
  sensitive   = true
  default     = "admin"
}

variable "dagster_s3_bucket_name" {
  description = "S3 bucket name for Dagster pipeline results"
  type        = string
  default     = null
}

variable "alert_webhook_url" {
  description = "Webhook URL for Dagster job failure alerts (optional)"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}

