resource "aws_iam_role" "karpenter_controller" {
  name = "${var.cluster_name}-karpenter-controller-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "pods.eks.amazonaws.com"
        }
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
      }
    ]
  })

  tags = var.tags
}

data "aws_iam_policy_document" "karpenter_controller" {
  statement {
    sid    = "AllowScopedEC2InstanceAccessActions"
    effect = "Allow"
    actions = [
      "ec2:CreateFleet",
      "ec2:CreateLaunchTemplate",
      "ec2:CreateTags",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeImages",
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceTypeOfferings",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeLaunchTemplates",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSpotPriceHistory",
      "ec2:DescribeSubnets",
      "ec2:DeleteLaunchTemplate",
      "ec2:TagResource",
      "ec2:UntagResource"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "AllowScopedEC2InstanceActionsWithTags"
    effect = "Allow"
    actions = [
      "ec2:RunInstances",
      "ec2:TerminateInstances"
    ]
    resources = [
      "arn:aws:ec2:*::image/*",
      "arn:aws:ec2:*::snapshot/*",
      "arn:aws:ec2:*:*:spot-instances-request/*",
      "arn:aws:ec2:*:*:launch-template/*"
    ]
    condition {
      test     = "StringEquals"
      variable = "ec2:ResourceTag/karpenter.sh/cluster"
      values   = [var.cluster_name]
    }
  }

  statement {
    sid    = "AllowEC2InstanceActionsOnDiscoveryTaggedResources"
    effect = "Allow"
    actions = [
      "ec2:RunInstances"
    ]
    resources = [
      "arn:aws:ec2:*:*:instance/*",
      "arn:aws:ec2:*::image/*",
      "arn:aws:ec2:*::snapshot/*",
      "arn:aws:ec2:*:*:spot-instances-request/*",
      "arn:aws:ec2:*:*:launch-template/*",
      "arn:aws:ec2:*:*:network-interface/*",
      "arn:aws:ec2:*:*:volume/*"
    ]
  }

  statement {
    sid    = "AllowEC2RunInstancesOnDiscoveryTaggedSubnetsAndSecurityGroups"
    effect = "Allow"
    actions = [
      "ec2:RunInstances"
    ]
    resources = [
      "arn:aws:ec2:*:*:security-group/*",
      "arn:aws:ec2:*:*:subnet/*"
    ]
    condition {
      test     = "StringEquals"
      variable = "ec2:ResourceTag/karpenter.sh/discovery"
      values   = [var.cluster_name]
    }
  }

  statement {
    sid    = "AllowScopedResourceCreationTagging"
    effect = "Allow"
    actions = [
      "ec2:CreateTags"
    ]
    resources = [
      "arn:aws:ec2:*:*:fleet/*",
      "arn:aws:ec2:*:*:instance/*",
      "arn:aws:ec2:*:*:launch-template/*",
      "arn:aws:ec2:*:*:spot-instances-request/*",
      "arn:aws:ec2:*:*:volume/*"
    ]
    condition {
      test     = "StringEquals"
      variable = "ec2:CreateAction"
      values = [
        "RunInstances",
        "CreateFleet",
        "CreateLaunchTemplate"
      ]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/karpenter.sh/cluster"
      values   = [var.cluster_name]
    }
  }

  statement {
    sid    = "AllowScopedDeletion"
    effect = "Allow"
    actions = [
      "ec2:TerminateInstances",
      "ec2:DeleteLaunchTemplate"
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "ec2:ResourceTag/karpenter.sh/cluster"
      values   = [var.cluster_name]
    }
  }

  statement {
    sid    = "AllowEKSDescribeCluster"
    effect = "Allow"
    actions = [
      "eks:DescribeCluster"
    ]
    resources = [
      "arn:aws:eks:*:*:cluster/${var.cluster_name}"
    ]
  }

  statement {
    sid    = "AllowPassNodeRole"
    effect = "Allow"
    actions = [
      "iam:PassRole"
    ]
    resources = [
      aws_iam_role.karpenter_node.arn
    ]
  }

  statement {
    sid    = "AllowSSMReadForAMISubnet"
    effect = "Allow"
    actions = [
      "ssm:GetParameter"
    ]
    resources = [
      "arn:aws:ssm:*:*:parameter/aws/service/eks/optimized-ami/*"
    ]
  }

  statement {
    sid    = "AllowPricingReadAccess"
    effect = "Allow"
    actions = [
      "pricing:GetProducts"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "AllowScopedNodeInstanceProfileCreation"
    effect = "Allow"
    actions = [
      "iam:CreateInstanceProfile",
      "iam:AddRoleToInstanceProfile",
      "iam:RemoveRoleFromInstanceProfile",
      "iam:DeleteInstanceProfile",
      "iam:GetInstanceProfile"
    ]
    resources = [
      "arn:aws:iam::*:instance-profile/karpenter.k8s.aws.cluster.${var.cluster_name}*"
    ]
  }

  statement {
    sid    = "AllowScopedNodeInstanceProfileTagging"
    effect = "Allow"
    actions = [
      "iam:TagInstanceProfile",
      "iam:UntagInstanceProfile"
    ]
    resources = [
      "arn:aws:iam::*:instance-profile/karpenter.k8s.aws.cluster.${var.cluster_name}*"
    ]
    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/karpenter.sh/cluster"
      values   = [var.cluster_name]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/Name"
      values   = ["${var.cluster_name}-karpenter-node"]
    }
  }

  statement {
    sid    = "AllowScopedNodeRoleRead"
    effect = "Allow"
    actions = [
      "iam:GetRole",
      "iam:ListAttachedRolePolicies",
      "iam:ListRolePolicies"
    ]
    resources = [
      "arn:aws:iam::*:role/karpenter.k8s.aws.cluster.${var.cluster_name}*"
    ]
  }
}

resource "aws_iam_role_policy" "karpenter_controller" {
  name   = "${var.cluster_name}-karpenter-controller-policy"
  role   = aws_iam_role.karpenter_controller.id
  policy = data.aws_iam_policy_document.karpenter_controller.json
}

resource "aws_iam_role" "karpenter_node" {
  name = "${var.cluster_name}-karpenter-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      "karpenter.sh/cluster" = var.cluster_name
      "Name"                 = "${var.cluster_name}-karpenter-node"
    }
  )
}

resource "aws_iam_role_policy_attachment" "karpenter_node_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.karpenter_node.name
}

resource "aws_iam_role_policy_attachment" "karpenter_node_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.karpenter_node.name
}

resource "aws_iam_role_policy_attachment" "karpenter_node_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.karpenter_node.name
}

resource "aws_iam_role_policy_attachment" "karpenter_node_AmazonSSMManagedInstanceCore" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.karpenter_node.name
}

resource "aws_iam_instance_profile" "karpenter_node" {
  name = "${var.cluster_name}-karpenter-node-instance-profile"
  role = aws_iam_role.karpenter_node.name

  tags = merge(
    var.tags,
    {
      "karpenter.sh/cluster"  = var.cluster_name
      "karpenter.sh/nodepool" = "true"
      "Name"                  = "${var.cluster_name}-karpenter-node"
    }
  )
}

resource "helm_release" "karpenter" {
  name       = "karpenter"
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter"
  version    = var.chart_version
  namespace  = "karpenter"

  create_namespace = true
  wait             = true
  wait_for_jobs    = true

  set = [
    {
      name  = "settings.clusterName"
      value = var.cluster_name
    },
    {
      name  = "settings.defaultInstanceProfile"
      value = aws_iam_instance_profile.karpenter_node.name
    },
    {
      name  = "settings.interruptionQueue"
      value = aws_sqs_queue.karpenter_interruption.name
    }
  ]

  depends_on = [
    aws_iam_instance_profile.karpenter_node,
    aws_eks_pod_identity_association.karpenter
  ]
}

resource "time_sleep" "wait_for_karpenter_crds" {
  create_duration = "30s"

  depends_on = [
    helm_release.karpenter
  ]
}

resource "aws_eks_pod_identity_association" "karpenter" {
  cluster_name    = var.cluster_name
  namespace       = "karpenter"
  service_account = "karpenter"
  role_arn        = aws_iam_role.karpenter_controller.arn

  depends_on = [
    var.cluster_pod_identity_agent_ready,
  ]
}

resource "aws_eks_access_entry" "karpenter_node" {
  cluster_name  = var.cluster_name
  principal_arn = aws_iam_role.karpenter_node.arn
  type          = "EC2_LINUX"

  depends_on = [
    var.cluster_pod_identity_agent_ready,
  ]
}

resource "aws_sqs_queue" "karpenter_interruption" {
  name                      = "${var.cluster_name}-karpenter-interruption"
  message_retention_seconds = 300

  tags = merge(
    var.tags,
    {
      "karpenter.sh/cluster" = var.cluster_name
    }
  )
}

resource "aws_sqs_queue_policy" "karpenter_interruption" {
  queue_url = aws_sqs_queue.karpenter_interruption.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = [
            "events.amazonaws.com",
            "sqs.amazonaws.com"
          ]
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.karpenter_interruption.arn
      }
    ]
  })
}

resource "aws_cloudwatch_event_rule" "karpenter_interruption" {
  name        = "${var.cluster_name}-karpenter-spot-interruption"
  description = "Karpenter Spot Instance Interruption Rule"

  event_pattern = jsonencode({
    source      = ["aws.ec2"]
    detail-type = ["EC2 Spot Instance Interruption Warning"]
  })

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "karpenter_interruption" {
  rule      = aws_cloudwatch_event_rule.karpenter_interruption.name
  target_id = "KarpenterInterruptionQueueTarget"
  arn       = aws_sqs_queue.karpenter_interruption.arn
}

resource "aws_cloudwatch_event_rule" "karpenter_rebalance" {
  name        = "${var.cluster_name}-karpenter-rebalance"
  description = "Karpenter Rebalance Recommendation Rule"

  event_pattern = jsonencode({
    source      = ["aws.ec2"]
    detail-type = ["EC2 Instance Rebalance Recommendation"]
  })

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "karpenter_rebalance" {
  rule      = aws_cloudwatch_event_rule.karpenter_rebalance.name
  target_id = "KarpenterRebalanceQueueTarget"
  arn       = aws_sqs_queue.karpenter_interruption.arn
}

resource "kubernetes_manifest" "karpenter_ec2_nodeclass_spot" {
  computed_fields = ["metadata.uid", "metadata.resourceVersion"]

  manifest = {
    apiVersion = "karpenter.k8s.aws/v1"
    kind       = "EC2NodeClass"
    metadata = {
      name = "dagster-spot-nodes"
    }
    spec = {
      amiFamily       = "AL2023"
      instanceProfile = aws_iam_instance_profile.karpenter_node.name
      amiSelectorTerms = [
        {
          alias = "al2023@latest"
        }
      ]
      subnetSelectorTerms = [
        {
          tags = {
            "karpenter.sh/discovery" = var.cluster_name
          }
        }
      ]
      securityGroupSelectorTerms = [
        {
          tags = {
            "karpenter.sh/discovery" = var.cluster_name
          }
        }
      ]
      tags = merge(
        var.tags,
        {
          "karpenter.sh/cluster" = var.cluster_name
          "NodeType"             = "spot"
          "Purpose"              = "dagster-jobs"
        }
      )
      metadataOptions = {
        httpEndpoint            = "enabled"
        httpProtocolIPv6        = "disabled"
        httpPutResponseHopLimit = 2
        httpTokens              = "required"
      }
      blockDeviceMappings = [
        {
          deviceName = "/dev/xvda"
          ebs = {
            volumeSize          = "20Gi"
            volumeType          = "gp3"
            deleteOnTermination = true
            encrypted           = true
          }
        }
      ]
    }
  }

  depends_on = [
    helm_release.karpenter
  ]
}

resource "kubernetes_manifest" "karpenter_nodepool_spot" {
  computed_fields = ["metadata.uid", "metadata.resourceVersion"]
  field_manager {
    force_conflicts = true
  }

  manifest = {
    apiVersion = "karpenter.sh/v1"
    kind       = "NodePool"
    metadata = {
      name = "dagster-spot-nodepool"
    }
    spec = {
      template = {
        metadata = {
          labels = {
            "node-type" = "spot"
            "purpose"   = "dagster-jobs"
          }
          annotations = {
            "karpenter.sh/do-not-disrupt" = "false"
          }
        }
        spec = {
          nodeClassRef = {
            group = "karpenter.k8s.aws"
            kind  = "EC2NodeClass"
            name  = "dagster-spot-nodes"
          }
          requirements = [
            {
              key      = "karpenter.sh/capacity-type"
              operator = "In"
              values   = ["spot"]
            },
            {
              key      = "karpenter.k8s.aws/instance-family"
              operator = "In"
              values   = ["t3"]
            },
            {
              key      = "karpenter.k8s.aws/instance-size"
              operator = "In"
              values   = ["small"]
            },
            {
              key      = "kubernetes.io/arch"
              operator = "In"
              values   = ["amd64"]
            },
            {
              key      = "kubernetes.io/os"
              operator = "In"
              values   = ["linux"]
            }
          ]
        }
      }
      limits = {
        cpu = "1000"
      }
      disruption = {
        consolidationPolicy = "WhenEmpty"
        consolidateAfter    = "30s"
      }
    }
  }

  depends_on = [
    kubernetes_manifest.karpenter_ec2_nodeclass_spot
  ]
}

