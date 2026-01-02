resource "helm_release" "kube_prometheus_stack" {
  name       = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = var.namespace
  version    = var.kube_prometheus_stack_version

  create_namespace = true

  values = [
    yamlencode({
      prometheus = {
        prometheusSpec = {
          retention = var.prometheus_retention
          resources = {
            requests = {
              cpu    = var.prometheus_cpu_request
              memory = var.prometheus_memory_request
            }
            limits = {
              cpu    = var.prometheus_cpu_limit
              memory = var.prometheus_memory_limit
            }
          }
          storageSpec = {
            volumeClaimTemplate = {
              spec = {
                accessModes = ["ReadWriteOnce"]
                resources = {
                  requests = {
                    storage = var.prometheus_storage_size
                  }
                }
              }
            }
          }
        }
        service = {
          type = "ClusterIP"
        }
      }
      grafana = {
        enabled = true
        adminUser = var.grafana_admin_user
        adminPassword = var.grafana_admin_password
        service = {
          type = "ClusterIP"
        }
        persistence = {
          enabled = true
          size    = var.grafana_storage_size
        }
        "grafana.ini" = {
          server = {
            root_url = "%(protocol)s://%(domain)s:%(http_port)s/grafana/"
            serve_from_sub_path = true
          }
        }
      }
      alertmanager = {
        enabled = var.alertmanager_enabled
        alertmanagerSpec = {
          storage = {
            volumeClaimTemplate = {
              spec = {
                accessModes = ["ReadWriteOnce"]
                resources = {
                  requests = {
                    storage = var.alertmanager_storage_size
                  }
                }
              }
            }
          }
        }
      }
      prometheusOperator = {
        resources = {
          requests = {
            cpu    = "100m"
            memory = "128Mi"
          }
          limits = {
            cpu    = "200m"
            memory = "256Mi"
          }
        }
      }
      kubeStateMetrics = {
        enabled = true
        resources = {
          requests = {
            cpu    = "100m"
            memory = "128Mi"
          }
          limits = {
            cpu    = "200m"
            memory = "256Mi"
          }
        }
      }
    })
  ]

  depends_on = [
    var.helm_depends_on,
  ]
}

resource "helm_release" "prometheus_pushgateway" {
  name       = "prometheus-pushgateway"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus-pushgateway"
  namespace  = var.namespace
  version    = var.pushgateway_version

  create_namespace = true

  values = [
    yamlencode({
      service = {
        type = "ClusterIP"
      }
      resources = {
        requests = {
          cpu    = var.pushgateway_cpu_request
          memory = var.pushgateway_memory_request
        }
        limits = {
          cpu    = var.pushgateway_cpu_limit
          memory = var.pushgateway_memory_limit
        }
      }
    })
  ]

  depends_on = [
    var.helm_depends_on,
  ]
}

resource "kubernetes_ingress_v1" "grafana" {
  metadata {
    name      = "grafana"
    namespace = var.namespace
    annotations = {
      "nginx.ingress.kubernetes.io/backend-protocol"     = "HTTP"
      "nginx.ingress.kubernetes.io/rewrite-target"        = "/$2"
      "nginx.ingress.kubernetes.io/use-regex"             = "true"
    }
  }
  spec {
    ingress_class_name = "nginx"
    rule {
      http {
        path {
          path      = "/grafana(/|$)(.*)"
          path_type = "ImplementationSpecific"
          backend {
            service {
              name = "kube-prometheus-stack-grafana"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }

  depends_on = [
    helm_release.kube_prometheus_stack,
  ]
}

resource "kubernetes_ingress_v1" "prometheus" {
  metadata {
    name      = "prometheus"
    namespace = var.namespace
    annotations = {
      "nginx.ingress.kubernetes.io/backend-protocol" = "HTTP"
    }
  }
  spec {
    ingress_class_name = "nginx"
    rule {
      http {
        path {
          path      = "/prometheus"
          path_type = "Prefix"
          backend {
            service {
              name = "kube-prometheus-stack-kube-prom-prometheus"
              port {
                number = 9090
              }
            }
          }
        }
      }
    }
  }

  depends_on = [
    helm_release.kube_prometheus_stack,
  ]
}

