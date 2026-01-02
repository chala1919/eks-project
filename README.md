# EKS Data Pipeline Infrastructure

Terraform setup for deploying an EKS cluster with Dagster data pipeline, secure S3 access via bastion host, and monitoring.

## Table of Contents

- [Infrastructure Design](#infrastructure-design)
- [How to Provision](#how-to-provision)
- [How to Use](#how-to-use)
- [How to Test](#how-to-test)
- [Technology Choices](#technology-choices)
- [Instance Types and Scaling](#instance-types-and-scaling)
- [Monitoring](#monitoring)
- [Security: Bastion-Only Data Access](#security-bastion-only-data-access)

---

## Infrastructure Design

### Architecture

The setup uses a multi-layered architecture:

```
VPC (2 AZs, public/private subnets, single NAT gateway)
  └─> EKS Cluster
      ├─> Managed Node Group (t3.small) - base capacity
      ├─> Karpenter (t3.small spot) - dynamic workloads
      └─> Applications
          ├─> ArgoCD (GitOps)
          ├─> Dagster (data pipeline)
          └─> Ingress (NGINX + ALB)
  └─> S3 Bucket (pipeline results)
  └─> Bastion Host (secure data access)
```

### Kubernetes Setup

**EKS**: Managed control plane, Kubernetes 1.34, CloudWatch logs enabled. Authentication uses `API_AND_CONFIG_MAP` mode.

**Node Strategy**:
- **Managed Node Group**: Base capacity for system pods (ArgoCD, Karpenter, ingress controllers)
- **Karpenter**: Auto-scales for Dagster jobs using spot instances

### Database

**PostgreSQL**: Embedded in Dagster Helm chart. Handles run history, asset metadata, and scheduling. For this setup it's fine, but in production you'd want a managed PostgreSQL database like RDS or Aurora for better reliability, automated backups, and high availability.

### Monitoring

**Current Setup**:
- **Prometheus + Grafana Stack**: Full monitoring with Prometheus for metrics, Grafana for dashboards, and Alertmanager for alerts
- CloudWatch Logs for EKS control plane
- EKS Node Monitoring Agent for node/pod metrics
- Dagster built-in observability (UI + run history)
- Dagster sensors for Slack alerts on job failures

You can use Grafana and Alertmanager to configure alerts about Dagster daemons, pods, and infrastructure. Monitor nodes, pod health, resource usage, and set up custom alerting rules for proactive issue detection.

---

## How to Provision

### Prerequisites

- Terraform >= 1.0
- AWS CLI configured
- kubectl installed
- Docker Hub account (for Dagster user code image)

### Setup Steps

1. **Configure S3 Backend for Terraform State**:
   
   Before running Terraform, you need to set up an S3 bucket for storing the Terraform state:
   
   ```bash
   # Create S3 bucket for Terraform state (replace with your bucket name)
   aws s3 mb s3://your-terraform-state-bucket --region eu-west-1
   
   # Enable versioning (recommended)
   aws s3api put-bucket-versioning \
     --bucket your-terraform-state-bucket \
     --versioning-configuration Status=Enabled
   
   # Enable encryption (recommended)
   aws s3api put-bucket-encryption \
     --bucket your-terraform-state-bucket \
     --server-side-encryption-configuration '{
       "Rules": [{
         "ApplyServerSideEncryptionByDefault": {
           "SSEAlgorithm": "AES256"
         }
       }]
     }'
   ```
   
   Then update `versions.tf` with your bucket name:
   ```hcl
   backend "s3" {
     bucket  = "your-terraform-state-bucket"  # Change this to your bucket name
     key     = "terraform.tfstate"
     region  = "eu-west-1"                    # Change to your region
     encrypt = true
   }
   ```
   
   **Note**: The backend configuration is in `versions.tf`. Make sure to update it before running `terraform init`.

2. **Build and push Dagster user code image**:
   ```bash
   cd argocd_apps/dagster-pipeline
   docker build -t docker.io/elyesjarroudi/dagster-user-code:latest .
   docker push docker.io/elyesjarroudi/dagster-user-code:latest
   cd ../..
   ```

3. **Configure variables** (create `terraform.tfvars`):
   ```hcl
   name_prefix    = "my-eks"
   cluster_name   = "my-eks-cluster"
   aws_region     = "eu-west-1"
   vpc_cidr       = "10.0.0.0/16"
   
   node_group_desired_size = 4
   node_group_max_size     = 10
   node_group_min_size     = 1
   ```

4. **Deploy**:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```
   Takes about 15-20 minutes.

5. **Configure kubectl**:
   ```bash
   aws eks update-kubeconfig --name <cluster-name> --region <region>
   kubectl get nodes
   ```

6. **Get ArgoCD password**:
   ```bash
   kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
   ```

---

## How to Use

### Access Dagster UI

Get the Dagster URL:

```bash
kubectl get ingress dagster-webserver -n dagster
```

The URL will be shown in the `ADDRESS` column. Open it in your browser.

### Trigger Dagster Job

**Via Dagster UI**:
1. Open the Dagster UI (from the URL above)
2. Go to "Jobs" in the sidebar
3. Find `product_pipeline_job`
4. Click "Launch Run"
5. Watch it execute in real-time

**Via CLI** (alternative):
```bash
kubectl port-forward -n dagster svc/dagster-dagster-webserver 3000:80
# Then in another terminal:
dagster job launch -j product_pipeline_job --workspace ws.yaml
```

### Test the Dagster Job

1. **Trigger a run** via the UI (see above)
2. **Check job status** in the Dagster UI - you should see:
   - `fetch_data` asset completes
   - `process_data` asset completes
   - `store_to_s3` asset completes
3. **Verify data in S3** (via bastion - see below)
4. **Check Slack** (if configured) - you'll get alerts if the job fails

The job fetches data from a public API, processes it, and stores the result as JSON in S3.

### Access Product Data via Bastion

The S3 bucket is only accessible via the bastion host (and EKS nodes). Here's how to access it:

1. **Get bastion info**:
   ```bash
   terraform output bastion_instance_id
   ```

2. **Connect to bastion**:
   ```bash
   aws ssm start-session --target <instance-id> --region eu-west-1
   ```

3. **Fetch data**:
   ```bash
   # List files
   /home/ec2-user/fetch-products.sh --list
   
   # Download all products
   /home/ec2-user/fetch-products.sh --download
   
   # Show summary
   /home/ec2-user/fetch-products.sh --summary
   ```

4. **Verify bastion-only access**: Try accessing S3 from your local machine - it should fail with `AccessDenied`:
   ```bash
   aws s3 ls s3://<bucket-name>/ --region eu-west-1
   # Error: AccessDenied
   ```

---

## How to Test

### Quick Health Check

```bash
# Check nodes
kubectl get nodes

# Check pods
kubectl get pods -A

# Check Dagster
kubectl get pods -n dagster
```

### Test Dagster Pipeline

1. Access Dagster UI (get URL from ingress)
2. Trigger `product_pipeline_job`
3. Verify it completes successfully
4. Check S3 via bastion to see the output file

### Test Bastion Access

1. Connect to bastion via SSM
2. Run the fetch script
3. Verify you can see the data files

### Test Monitoring

```bash
# Check CloudWatch logs
aws logs describe-log-groups --log-group-name-prefix /aws/eks

# View control plane logs
aws logs tail /aws/eks/<cluster-name>/cluster --follow
```

### End-to-End Test

1. Trigger pipeline via Dagster UI
2. Wait for completion
3. Connect to bastion
4. Fetch and verify data
5. Try direct S3 access (should fail)

---

## Technology Choices

### Kubernetes: Amazon EKS

Chose EKS because it's managed - no need to maintain the control plane. Good AWS integration with IAM, VPC, and CloudWatch. Automatic security patches. Could have used self-managed kubeadm, but that's too much operational overhead.

### Autoscaling: Karpenter

Karpenter is faster than Cluster Autoscaler (seconds vs minutes) and better at spot instance management. Built specifically for EKS. Cluster Autoscaler works but is slower and more complex to configure.

### Data Pipeline: Dagster

Dagster has better Kubernetes integration and a modern architecture compared to Airflow. The UI is great for debugging. Airflow is more complex to set up and heavier on resources.

### GitOps: ArgoCD

ArgoCD has a solid UI and is battle-tested. Self-healing and multi-cluster support. Flux is good too but has a less mature UI.

### Storage: S3

S3 is perfect for data pipeline outputs - scalable, cheap, durable. RDS/DynamoDB would be overkill for JSON files. EFS is more expensive and complex.

### Security: Bastion Host

Bastion pattern provides better security than direct S3 access. All access is logged, and you can add VPN/MFA if needed. Meets compliance requirements.

---

## Instance Types and Scaling

### Base Node Group: t3.small

**Current Setup**: Using `t3.small` (2 vCPU, 2 GiB memory) for the managed node group.

**Why t3.small**:
- Cheap (~$15/month per node)
- Burstable performance fits system pods (ArgoCD, Karpenter, ingress) which have low baseline but occasional spikes
- System pods need ~1 vCPU, 1 GiB baseline - t3.small gives 100% headroom
- Min: 1, Desired: 4 (redundancy), Max: 10

**Production Note**: In production, I'd use AMD instances like `m5a.large` or `c5a.xlarge` since they're cheaper, with better performance and no burst limits. The t3.small is fine for this demo but production workloads need consistent performance.

### Dynamic Workloads: Karpenter with t3.small Spot

**Current Setup**: Karpenter uses `t3.small` spot instances for Dagster jobs.

**Why spot**:
- 60-80% cost savings
- Dagster jobs are short-lived and can handle interruptions
- Karpenter automatically handles spot interruptions
- Max CPU limit: 1000 vCPU (prevents runaway costs)
- Consolidation: 30s after empty (aggressive cost optimization)

**Production Note**: For production, I'd use a mix of on-demand and spot (maybe 70/30 split) for critical workloads, and larger AMD instance types (m5a.xlarge or c5a.2xlarge) since they're cheaper.

### Scaling Strategy

**Two-tier approach**:
1. **Base layer** (Managed Node Group): On-demand t3.small for system pods
2. **Dynamic layer** (Karpenter): Spot t3.small for workloads

This works because the base layer is minimal (4 nodes), and the dynamic layer only pays for what's used. Karpenter provisions nodes in seconds when needed.

---

## Monitoring

### Current Setup

**CloudWatch Logs**: EKS control plane logs (API, audit, scheduler, etc.). 7-day retention. Good for debugging and compliance.

**EKS Node Monitoring Agent**: Automatic addon that collects node and pod metrics. Goes to CloudWatch under `ContainerInsights` namespace. Low overhead (<1% CPU).

**Prometheus + Grafana Stack**:
- **Prometheus**: Collects metrics from all pods, nodes, and infrastructure components
- **Grafana**: Dashboards for visualizing metrics and system health
- **Alertmanager**: Configure alerts for Dagster daemons, pods, and infrastructure issues
- **kube-state-metrics**: Exposes Kubernetes object metrics (pods, nodes, deployments, etc.)

**What You Can Monitor**:
- **Dagster Components**: All Dagster pods (webserver, user code deployments, daemons) - CPU, memory, restarts, errors
- **Infrastructure**: Node health, resource usage, disk space, network metrics
- **Kubernetes**: Pod status, deployment health, service availability
- **Custom Alerts**: Configure Alertmanager rules to alert on Dagster daemon failures, pod crashes, high resource usage, etc.

**Dagster Built-in**:
- Run history in PostgreSQL
- UI for visualizing jobs and assets
- **Sensors for Slack alerts**: We use Dagster's `run_status_sensor` to send Slack notifications when jobs fail. This is sufficient for job failure alerts.

**Access Grafana**:
- URL: `http://<alb-hostname>/grafana`
- Username: `admin`
- Password: `admin` (get from secret: `kubectl get secret -n monitoring kube-prometheus-stack-grafana -o jsonpath='{.data.admin-password}' | base64 -d`)

**Why This Works**:
- Comprehensive monitoring of all Dagster components, not just job failures
- Infrastructure and node monitoring for proactive issue detection
- Customizable dashboards and alerting rules
- Can configure Alertmanager to send notifications to Slack, email, PagerDuty, etc.

### Production Considerations

The current Prometheus + Grafana setup provides production-ready monitoring. For additional capabilities:

**Additional Tools** (optional):
- OpenTelemetry for distributed tracing
- AWS X-Ray for request tracing
- CloudWatch Synthetics for end-to-end monitoring
- Long-term metrics storage (Thanos, Cortex, or CloudWatch)

---

## Security: Bastion-Only Data Access

### How It Works

The S3 bucket policy only allows access from:
1. Bastion host IAM role (read-only)
2. EKS node group IAM role (read-only)
3. Dagster user code IAM role (read-write)

Everything else is denied.

### Verify It Works

1. **Check bucket policy**:
   ```bash
   BUCKET_NAME=$(terraform output -raw s3_bucket_name 2>/dev/null || echo "your-bucket-name")
   aws s3api get-bucket-policy --bucket $BUCKET_NAME --region eu-west-1
   ```
   Should show only the three roles above.

2. **Try direct access** (should fail):
   ```bash
   aws s3 ls s3://$BUCKET_NAME/ --region eu-west-1
   # AccessDenied
   ```

3. **Access via bastion** (should work):
   ```bash
   aws ssm start-session --target <instance-id> --region eu-west-1
   /home/ec2-user/fetch-products.sh --list
   ```

### Security Benefits

- Principle of least privilege (only specific roles can access)
- Network isolation (requires SSH/SSM to bastion)
- Audit trail (all S3 access logged in CloudTrail)
- No public access (bucket has BlockPublicAccess enabled)
- Encryption at rest (AWS-managed keys)

---

<!-- BEGIN_TF_DOCS -->