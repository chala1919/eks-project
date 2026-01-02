resource "aws_security_group" "alb" {
  name        = "${var.cluster_name}-alb-sg"
  description = "Security group for ALB pointing to NGINX Ingress Controller"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-alb-sg"
    }
  )
}

resource "aws_security_group_rule" "alb_to_nodes" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = var.node_security_group_id
  description              = "Allow traffic from ALB to EKS nodes"
}

resource "helm_release" "nginx_ingress" {
  name       = "nginx-ingress"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = var.namespace
  version    = var.chart_version

  create_namespace = true

  values = [
    yamlencode({
      controller = {
        service = {
          type = "ClusterIP"
        }
        replicaCount = var.replica_count
        resources = {
          requests = {
            cpu    = var.resource_requests_cpu
            memory = var.resource_requests_memory
          }
          limits = {
            cpu    = var.resource_limits_cpu
            memory = var.resource_limits_memory
          }
        }
      }
    })
  ]

  depends_on = [
    var.helm_depends_on,
  ]
}

resource "kubernetes_ingress_v1" "main_alb" {
  metadata {
    name      = "nginx-ingress-alb"
    namespace = var.namespace
    annotations = {
      "alb.ingress.kubernetes.io/scheme"           = var.alb_scheme
      "alb.ingress.kubernetes.io/target-type"      = "ip"
      "alb.ingress.kubernetes.io/backend-protocol" = "HTTP"
      "alb.ingress.kubernetes.io/listen-ports"     = jsonencode([{ HTTP = 80 }])
      "alb.ingress.kubernetes.io/security-groups"  = aws_security_group.alb.id
      "alb.ingress.kubernetes.io/healthcheck-path" = "/healthz"
    }
  }

  spec {
    ingress_class_name = "alb"
    rule {
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "${helm_release.nginx_ingress.name}-${helm_release.nginx_ingress.chart}-controller"
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
    helm_release.nginx_ingress,
    var.helm_depends_on,
    aws_security_group.alb,
    aws_security_group_rule.alb_to_nodes,
  ]
}

data "kubernetes_ingress_v1" "main_alb" {
  metadata {
    name      = "nginx-ingress-alb"
    namespace = var.namespace
  }

  depends_on = [
    kubernetes_ingress_v1.main_alb,
    var.helm_depends_on,
  ]
}
