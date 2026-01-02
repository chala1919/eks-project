resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = var.namespace
  version    = var.chart_version

  create_namespace = true

  values = [
    yamlencode({
      server = {
        ingress = {
          enabled = false
        }
        service = {
          type          = "ClusterIP"
          servicePort   = 80
          containerPort = 8080
        }
        extraArgs = [
          "--basehref",
          "/argocd",
          "--rootpath",
          "/argocd",
          "--insecure"
        ]
        configs = {
          params = {
            "server.rootpath" = ""
          }
        }
      }
      dex = {
        enabled = false
      }
    })
  ]

  depends_on = [
    var.helm_depends_on,
  ]
}

resource "kubernetes_ingress_v1" "argocd" {
  metadata {
    name      = "argocd-server"
    namespace = var.namespace
    annotations = {
      "nginx.ingress.kubernetes.io/backend-protocol" = "HTTP"
      "nginx.ingress.kubernetes.io/ssl-redirect"     = "false"
    }
  }
  spec {
    ingress_class_name = "nginx"
    rule {
      http {
        path {
          path      = "/argocd"
          path_type = "Prefix"
          backend {
            service {
              name = "argocd-server"
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
    helm_release.argocd,
  ]
}
