resource "time_sleep" "wait_for_argocd_crds" {
  depends_on      = [var.argocd_helm_release]
  create_duration = "120s"
}

resource "null_resource" "wait_for_application_crd" {
  depends_on = [time_sleep.wait_for_argocd_crds]

  provisioner "local-exec" {
    command     = "kubectl wait --for=condition=established --timeout=300s crd/applications.argoproj.io 2>&1 | Out-Null; if ($LASTEXITCODE -ne 0) { Write-Host 'CRD not ready yet, continuing anyway...' }"
    interpreter = ["PowerShell", "-Command"]
  }

  triggers = {
    argocd_release = var.argocd_helm_release.id
  }
}

resource "kubernetes_secret_v1" "dagster_repository" {
  metadata {
    name      = "dagster-helm-repo"
    namespace = var.argocd_namespace
    labels = {
      "argocd.argoproj.io/secret-type" = "repository"
    }
  }
  type = "Opaque"
  data = {
    type     = base64encode("helm")
    name     = base64encode("dagster-helm")
    url      = base64encode("https://dagster-io.github.io/helm")
    username = base64encode("")
    password = base64encode("")
  }

  depends_on = [
    null_resource.wait_for_application_crd,
  ]
}

resource "kubernetes_manifest" "dagster_application" {
  computed_fields = ["metadata.annotations", "metadata.labels", "status"]
  field_manager {
    force_conflicts = true
  }
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "dagster"
      namespace = var.argocd_namespace
      finalizers = [
        "resources-finalizer.argocd.argoproj.io"
      ]
    }
    spec = {
      project = "default"
      source = {
        repoURL        = "https://dagster-io.github.io/helm"
        chart          = "dagster"
        targetRevision = var.chart_version != null ? var.chart_version : "1.10.4"
        helm = {
          skipSchemaValidation = true
          values               = <<-EOT
postgresql:
  enabled: true

dagsterWebserver:
  service:
    type: ClusterIP
    port: 80

runLauncher:
  type: K8sRunLauncher
  config:
    k8sRunLauncher:
      image:
        repository: docker.io/elyesjarroudi/dagster-user-code
        tag: latest
        pullPolicy: Always
      imagePullPolicy: Always
      serviceAccountName: dagster-user-code
      jobNamespace: dagster

dagster-user-deployments:
  enabled: true
  deployments:
    - name: product-pipeline
      image:
        repository: docker.io/elyesjarroudi/dagster-user-code
        tag: latest
        pullPolicy: Always
      dagsterApiGrpcArgs:
        - "--python-file"
        - "/opt/dagster/app/product_job.py"
      port: 4000
      env:
        - name: S3_BUCKET_NAME
          value: ${aws_s3_bucket.dagster_pipeline.id}
        - name: AWS_REGION
          value: ${var.aws_region}
        - name: ALERT_WEBHOOK_URL
          value: ${var.alert_webhook_url != null && var.alert_webhook_url != "" ? var.alert_webhook_url : "https://hooks.slack.com/services/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"}
        - name: DAGSTER_UI_URL
          value: ${var.dagster_ui_url != null ? var.dagster_ui_url : ""}
      serviceAccount:
        create: true
        name: dagster-user-code
EOT
        }
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = var.namespace
      }
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
        syncOptions = [
          "CreateNamespace=true",
          "SkipSchemaValidation=true"
        ]
      }
    }
  }

  depends_on = [
    null_resource.wait_for_application_crd,
    kubernetes_secret_v1.dagster_repository,
  ]
}

resource "kubernetes_ingress_v1" "dagster" {
  metadata {
    name      = "dagster-webserver"
    namespace = var.namespace
    annotations = {
      "nginx.ingress.kubernetes.io/backend-protocol"               = "HTTP"
      "nginx.ingress.kubernetes.io/proxy-connect-timeout"          = "300"
      "nginx.ingress.kubernetes.io/proxy-send-timeout"             = "300"
      "nginx.ingress.kubernetes.io/proxy-read-timeout"             = "300"
      "nginx.ingress.kubernetes.io/upstream-keepalive-timeout"     = "300"
      "nginx.ingress.kubernetes.io/proxy-next-upstream-timeout"    = "300"
      "nginx.ingress.kubernetes.io/proxy-next-upstream"            = "error timeout http_502 http_503"
      "nginx.ingress.kubernetes.io/upstream-keepalive-connections" = "10"
      "nginx.ingress.kubernetes.io/upstream-keepalive-requests"    = "100"
    }
  }
  spec {
    ingress_class_name = "nginx"
    rule {
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "dagster-dagster-webserver"
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
    kubernetes_manifest.dagster_application,
  ]
}

