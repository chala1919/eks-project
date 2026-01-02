$ErrorActionPreference = "Stop"

Write-Host "=========================================="
Write-Host "Terraform Deployment Script"
Write-Host "=========================================="
Write-Host ""

if (-not (Get-Command terraform -ErrorAction SilentlyContinue)) {
    Write-Host "Error: terraform is not installed"
    exit 1
}

if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
    Write-Host "Warning: kubectl is not installed. URLs may not be available immediately."
}

Write-Host "Step 1: Initializing Terraform..."
terraform init
Write-Host ""

Write-Host "Step 2: Deploying VPC..."
terraform apply -target="module.vpc" -auto-approve
Write-Host ""

Write-Host "Step 3: Deploying EKS cluster and dependencies..."
terraform apply -target="module.eks" -target="aws_iam_role.vpc_cni_addon" -target="aws_iam_role.ebs_csi_addon" -auto-approve
Write-Host ""

Write-Host "Step 4: Deploying EKS addons..."
terraform apply -target="module.eks_addons" -auto-approve
Write-Host ""

Write-Host "Step 5: Deploying ALB controller and NGINX ingress..."
terraform apply -target="module.alb_controller" -target="module.nginx_ingress" -auto-approve
Write-Host ""

Write-Host "Step 6: Deploying remaining resources..."
terraform apply -auto-approve
Write-Host ""

Write-Host "Waiting for ingress resources to be ready..."
Start-Sleep -Seconds 30

Write-Host ""
Write-Host "=========================================="
Write-Host "Deployment Complete!"
Write-Host "=========================================="
Write-Host ""

$ALB_DNS = terraform output -raw nginx_ingress_alb_dns 2>$null
if ([string]::IsNullOrEmpty($ALB_DNS) -and (Get-Command kubectl -ErrorAction SilentlyContinue)) {
    Write-Host "Getting ALB DNS from Kubernetes ingress..."
    $ALB_DNS = kubectl get ingress nginx-ingress-alb -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>$null
}

$BASTION_IP = terraform output -raw bastion_public_ip 2>$null

Write-Host "Access URLs:"
Write-Host ""

if (-not [string]::IsNullOrEmpty($ALB_DNS)) {
    Write-Host "Dagster UI:"
    Write-Host "  http://$ALB_DNS/"
    Write-Host ""
    
    Write-Host "ArgoCD:"
    Write-Host "  http://$ALB_DNS/argocd"
    Write-Host ""
    
    Write-Host "Grafana:"
    Write-Host "  http://$ALB_DNS/grafana"
    Write-Host ""
} else {
    Write-Host "ALB DNS not available yet. Run:"
    Write-Host "  kubectl get ingress nginx-ingress-alb -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'"
    Write-Host ""
}

if (-not [string]::IsNullOrEmpty($BASTION_IP)) {
    Write-Host "Bastion Host Public IP:"
    Write-Host "  $BASTION_IP"
    Write-Host ""
    Write-Host "Connect to bastion:"
    $INSTANCE_ID = terraform output -raw bastion_instance_id 2>$null
    if (-not [string]::IsNullOrEmpty($INSTANCE_ID)) {
        Write-Host "  aws ssm start-session --target $INSTANCE_ID --region eu-west-1"
    }
    Write-Host ""
} else {
    Write-Host "Bastion IP not available. Get it with:"
    Write-Host "  terraform output bastion_public_ip"
    Write-Host ""
}

if (Get-Command kubectl -ErrorAction SilentlyContinue) {
    $ARGOCD_PASSWORD_B64 = kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>$null
    if (-not [string]::IsNullOrEmpty($ARGOCD_PASSWORD_B64)) {
        $ARGOCD_PASSWORD = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($ARGOCD_PASSWORD_B64))
        Write-Host "ArgoCD Credentials:"
        Write-Host "  Username: admin"
        Write-Host "  Password: $ARGOCD_PASSWORD"
        Write-Host ""
    }
}

if (Get-Command kubectl -ErrorAction SilentlyContinue) {
    $GRAFANA_PASSWORD_B64 = kubectl get secret -n monitoring kube-prometheus-stack-grafana -o jsonpath='{.data.admin-password}' 2>$null
    if (-not [string]::IsNullOrEmpty($GRAFANA_PASSWORD_B64)) {
        $GRAFANA_PASSWORD = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($GRAFANA_PASSWORD_B64))
        Write-Host "Grafana Credentials:"
        Write-Host "  Username: admin"
        Write-Host "  Password: $GRAFANA_PASSWORD"
        Write-Host ""
    }
}

Write-Host "=========================================="
Write-Host "All done!"
Write-Host "=========================================="

