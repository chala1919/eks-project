resource "time_sleep" "wait_for_cluster" {
  depends_on      = [var.cluster_id]
  create_duration = "60s"
}

resource "aws_security_group_rule" "node_to_node_http" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = var.node_security_group_id
  security_group_id        = var.node_security_group_id
  description              = "Allow HTTP traffic between pods (for ingress backends)"
}

resource "kubernetes_storage_class_v1" "gp3" {
  metadata {
    name = "gp3"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }
  storage_provisioner    = "ebs.csi.aws.com"
  volume_binding_mode    = "WaitForFirstConsumer"
  allow_volume_expansion = true
  reclaim_policy         = "Delete"
  parameters = {
    type      = "gp3"
    encrypted = "true"
    fsType    = "ext4"
  }

  depends_on = [
    time_sleep.wait_for_cluster,
  ]
}

