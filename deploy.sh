#!/bin/bash

set -e

echo "=========================================="
echo "Terraform Deployment Script"
echo "=========================================="
echo ""

if ! command -v terraform &> /dev/null; then
    echo "Error: terraform is not installed"
    exit 1
fi

if ! command -v kubectl &> /dev/null; then
    echo "Warning: kubectl is not installed. URLs may not be available immediately."
fi

echo "Step 1: Initializing Terraform..."
terraform init
echo ""

echo "Step 2: Deploying VPC..."
terraform apply -target="module.vpc" -auto-approve
echo ""

echo "Step 3: Deploying EKS cluster and dependencies..."
terraform apply -target="module.eks" -target="aws_iam_role.vpc_cni_addon" -target="aws_iam_role.ebs_csi_addon" -auto-approve
echo ""

echo "Step 4: Deploying EKS addons..."
terraform apply -target="module.eks_addons" -auto-approve
echo ""

echo "Step 5: Deploying ALB controller and NGINX ingress..."
terraform apply -target="module.alb_controller" -target="module.nginx_ingress" -auto-approve
echo ""

echo "Step 6: Deploying remaining resources..."
terraform apply -auto-approve
echo ""

echo "Waiting for ingress resources to be ready..."
sleep 30

echo ""
echo "=========================================="
echo "Deployment Complete!"
echo "=========================================="
echo ""

ALB_DNS=$(terraform output -raw nginx_ingress_alb_dns 2>/dev/null || echo "")

if [ -z "$ALB_DNS" ] && command -v kubectl &> /dev/null; then
    echo "Getting ALB DNS from Kubernetes ingress..."
    ALB_DNS=$(kubectl get ingress nginx-ingress-alb -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
fi

BASTION_IP=$(terraform output -raw bastion_public_ip 2>/dev/null || echo "")

echo "Access URLs:"
echo ""

if [ -n "$ALB_DNS" ]; then
    echo "Dagster UI:"
    echo "  http://${ALB_DNS}/"
    echo ""
    
    echo "ArgoCD:"
    echo "  http://${ALB_DNS}/argocd"
    echo ""
    
    echo "Grafana:"
    echo "  http://${ALB_DNS}/grafana"
    echo ""
else
    echo "ALB DNS not available yet. Run:"
    echo "  kubectl get ingress nginx-ingress-alb -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'"
    echo ""
fi

if [ -n "$BASTION_IP" ]; then
    echo "Bastion Host Public IP:"
    echo "  ${BASTION_IP}"
    echo ""
    echo "Connect to bastion:"
    INSTANCE_ID=$(terraform output -raw bastion_instance_id 2>/dev/null || echo "")
    if [ -n "$INSTANCE_ID" ]; then
        echo "  aws ssm start-session --target ${INSTANCE_ID} --region eu-west-1"
    fi
    echo ""
else
    echo "Bastion IP not available. Get it with:"
    echo "  terraform output bastion_public_ip"
    echo ""
fi

if command -v kubectl &> /dev/null; then
    ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>/dev/null | base64 -d 2>/dev/null || echo "")
    if [ -n "$ARGOCD_PASSWORD" ]; then
        echo "ArgoCD Credentials:"
        echo "  Username: admin"
        echo "  Password: ${ARGOCD_PASSWORD}"
        echo ""
    fi
fi

if command -v kubectl &> /dev/null; then
    GRAFANA_PASSWORD=$(kubectl get secret -n monitoring kube-prometheus-stack-grafana -o jsonpath='{.data.admin-password}' 2>/dev/null | base64 -d 2>/dev/null || echo "")
    if [ -n "$GRAFANA_PASSWORD" ]; then
        echo "Grafana Credentials:"
        echo "  Username: admin"
        echo "  Password: ${GRAFANA_PASSWORD}"
        echo ""
    fi
fi

echo "=========================================="
echo "All done!"
echo "=========================================="
