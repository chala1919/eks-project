data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.name_prefix}-vpc"
  cidr = var.vpc_cidr

  azs             = var.availability_zones != null ? var.availability_zones : slice(data.aws_availability_zones.available.names, 0, min(2, length(data.aws_availability_zones.available.names)))
  public_subnets  = var.public_subnet_cidrs
  private_subnets = var.private_subnet_cidrs

  enable_nat_gateway = true
  single_nat_gateway = true
  enable_vpn_gateway = false

  enable_dns_hostnames = true
  enable_dns_support   = true

  public_subnet_tags = {
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "karpenter.sh/discovery"                    = var.cluster_name
  }

  tags = var.tags
}

resource "aws_iam_role" "vpc_cni_addon" {
  name = "${var.cluster_name}-vpc-cni-addon-role"

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

resource "aws_iam_role_policy_attachment" "vpc_cni_addon_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.vpc_cni_addon.name
}

resource "aws_iam_role" "ebs_csi_addon" {
  name = "${var.cluster_name}-ebs-csi-addon-role"

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

resource "aws_iam_role_policy_attachment" "ebs_csi_addon_AmazonEBSCSIDriverPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi_addon.name
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.kubernetes_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  enable_cluster_creator_admin_permissions = true
  authentication_mode                      = "API_AND_CONFIG_MAP"

  cluster_enabled_log_types              = var.enabled_cluster_log_types
  cloudwatch_log_group_retention_in_days = var.log_retention_days

  eks_managed_node_groups = {
    main = {
      name           = "main"
      instance_types = ["t3.small"]

      min_size     = var.node_group_min_size
      max_size     = var.node_group_max_size
      desired_size = var.node_group_desired_size

      metadata_options = {
        http_endpoint               = "enabled"
        http_tokens                 = "required"
        http_put_response_hop_limit = 2
      }

      update_config = {
        max_unavailable = 1
      }
    }
  }

  cluster_addons = {
    eks-pod-identity-agent = {
      most_recent = var.addon_eks_pod_identity_agent_version == null
      version     = var.addon_eks_pod_identity_agent_version
    }
    vpc-cni = {
      most_recent = var.addon_vpc_cni_version == null
      version     = var.addon_vpc_cni_version
      pod_identity_association = [{
        role_arn        = aws_iam_role.vpc_cni_addon.arn
        service_account = "aws-node"
      }]
    }
    kube-proxy = {
      most_recent = var.addon_kube_proxy_version == null
      version     = var.addon_kube_proxy_version
    }
    coredns = {
      most_recent = var.addon_coredns_version == null
      version     = var.addon_coredns_version
    }
    aws-ebs-csi-driver = {
      most_recent = var.addon_ebs_csi_version == null
      version     = var.addon_ebs_csi_version
      pod_identity_association = [{
        role_arn        = aws_iam_role.ebs_csi_addon.arn
        service_account = "ebs-csi-controller-sa"
      }]
    }
    eks-node-monitoring-agent = {
      most_recent = var.addon_node_monitoring_agent_version == null
      version     = var.addon_node_monitoring_agent_version
    }
  }

  tags = var.tags

  node_security_group_tags = merge(
    var.tags,
    {
      "karpenter.sh/discovery" = var.cluster_name
    }
  )

  depends_on = [module.vpc]
}

module "eks_addons" {
  source = "./modules/eks-addons"

  cluster_id             = module.eks.cluster_id
  node_security_group_id = module.eks.node_security_group_id

  depends_on = [module.eks]
}

module "alb_controller" {
  source = "./modules/alb-controller"

  cluster_name                       = module.eks.cluster_name
  cluster_endpoint                   = module.eks.cluster_endpoint
  cluster_certificate_authority_data = module.eks.cluster_certificate_authority_data
  vpc_id                             = module.vpc.vpc_id
  subnet_ids                         = concat(module.vpc.public_subnets, module.vpc.private_subnets)

  controller_version = var.alb_controller_version
  tags               = var.tags

  depends_on = [
    module.eks,
    module.eks_addons,
  ]
}

module "nginx_ingress" {
  source = "./modules/nginx-ingress-controller"

  cluster_name           = module.eks.cluster_name
  vpc_id                 = module.vpc.vpc_id
  node_security_group_id = module.eks.node_security_group_id
  public_subnet_ids      = module.vpc.public_subnets
  private_subnet_ids     = module.vpc.private_subnets
  alb_scheme             = "internet-facing"
  chart_version          = var.nginx_ingress_chart_version
  tags                   = var.tags

  helm_depends_on = [module.alb_controller]

  depends_on = [module.eks]
}

module "argocd" {
  source = "./modules/argocd"

  hostname      = ""
  chart_version = var.argocd_chart_version

  helm_depends_on = [module.nginx_ingress]

  depends_on = [
    module.eks_addons,
    module.nginx_ingress,
  ]
}

module "karpenter" {
  source = "./modules/karpenter"

  cluster_name                       = module.eks.cluster_name
  cluster_endpoint                   = module.eks.cluster_endpoint
  cluster_certificate_authority_data = module.eks.cluster_certificate_authority_data
  subnet_ids                         = module.vpc.private_subnets
  node_security_group_id             = module.eks.node_security_group_id
  cluster_pod_identity_agent_ready   = module.eks.cluster_id

  chart_version = var.karpenter_chart_version
  tags          = var.tags

  depends_on = [
    module.eks,
    module.eks_addons,
  ]
}

module "dagster" {
  source = "./modules/dagster"

  name_prefix                      = var.name_prefix
  cluster_name                     = module.eks.cluster_name
  argocd_namespace                 = "argocd"
  namespace                        = "dagster"
  chart_version                    = var.dagster_chart_version
  argocd_helm_release              = module.argocd.helm_release
  s3_bucket_name                   = var.dagster_s3_bucket_name
  aws_region                       = var.aws_region
  alert_webhook_url                = var.alert_webhook_url != null ? var.alert_webhook_url : "https://hooks.slack.com/services/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"
  dagster_ui_url                   = ""
  cluster_pod_identity_agent_ready = module.eks.cluster_id
  tags                             = var.tags

  depends_on = [
    module.argocd,
    module.eks,
  ]
}

module "product_api" {
  source = "./modules/product-api"

  name_prefix         = var.name_prefix
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnets
  public_subnet_ids  = module.vpc.public_subnets
  s3_bucket_name     = module.dagster.s3_bucket_name
  aws_region         = var.aws_region
  tags               = var.tags

  depends_on = [
    module.dagster,
    module.vpc,
  ]
}

module "monitoring" {
  source = "./modules/monitoring"

  namespace                    = "monitoring"
  kube_prometheus_stack_version = var.kube_prometheus_stack_version
  pushgateway_version          = var.pushgateway_version
  grafana_admin_password        = var.grafana_admin_password

  helm_depends_on = [module.nginx_ingress]

  depends_on = [
    module.nginx_ingress,
    module.eks,
  ]
}

resource "aws_s3_bucket_policy" "dagster_pipeline" {
  bucket = module.dagster.s3_bucket_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowBastionHostAccess"
        Effect = "Allow"
        Principal = {
          AWS = module.product_api.bastion_role_arn
        }
        Action = [
          "s3:ListBucket",
          "s3:GetObject"
        ]
        Resource = [
          module.dagster.s3_bucket_arn,
          "${module.dagster.s3_bucket_arn}/*"
        ]
      },
      {
        Sid    = "AllowEKSNodeGroupAccess"
        Effect = "Allow"
        Principal = {
          AWS = module.eks.eks_managed_node_groups["main"].iam_role_arn
        }
        Action = [
          "s3:ListBucket",
          "s3:GetObject"
        ]
        Resource = [
          module.dagster.s3_bucket_arn,
          "${module.dagster.s3_bucket_arn}/*"
        ]
      },
      {
        Sid    = "AllowDagsterUserCodeAccess"
        Effect = "Allow"
        Principal = {
          AWS = module.dagster.dagster_user_code_role_arn
        }
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          module.dagster.s3_bucket_arn,
          "${module.dagster.s3_bucket_arn}/*"
        ]
      }
    ]
  })

  depends_on = [
    module.product_api,
    module.dagster,
    module.eks,
  ]
}
