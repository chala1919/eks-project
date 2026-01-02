output "prometheus_service_name" {
  description = "Name of the Prometheus service"
  value       = "kube-prometheus-stack-kube-prom-prometheus"
}

output "grafana_service_name" {
  description = "Name of the Grafana service"
  value       = "kube-prometheus-stack-grafana"
}

output "pushgateway_service_name" {
  description = "Name of the Pushgateway service"
  value       = "prometheus-pushgateway"
}

output "namespace" {
  description = "Namespace where monitoring components are deployed"
  value       = var.namespace
}

