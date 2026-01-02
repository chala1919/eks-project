output "nginx_ingress_namespace" {
  description = "Namespace where NGINX Ingress Controller is installed"
  value       = var.namespace
}

output "nginx_ingress_service_name" {
  description = "Name of the NGINX Ingress Controller service"
  value       = "${helm_release.nginx_ingress.name}-controller"
}

output "alb_dns_name" {
  description = "DNS name of the ALB created for NGINX Ingress Controller"
  value       = try(data.kubernetes_ingress_v1.main_alb.status[0].load_balancer[0].ingress[0].hostname, null)
}


