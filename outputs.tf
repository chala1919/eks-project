output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_arn" {
  description = "ARN of the EKS cluster"
  value       = module.eks.cluster_arn
}

output "cluster_version" {
  description = "Kubernetes version of the EKS cluster"
  value       = module.eks.cluster_version
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.vpc.private_subnets
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnets
}

output "bastion_public_ip" {
  description = "Public IP address of the bastion host"
  value       = module.product_api.bastion_public_ip
}

output "bastion_instance_id" {
  description = "Instance ID of the bastion host"
  value       = module.product_api.bastion_instance_id
}

output "nginx_ingress_alb_dns" {
  description = "DNS name of the ALB for NGINX Ingress Controller"
  value       = module.nginx_ingress.alb_dns_name
}

