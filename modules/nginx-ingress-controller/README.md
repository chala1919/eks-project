<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |
| <a name="provider_helm"></a> [helm](#provider\_helm) | n/a |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_security_group.alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.alb_to_nodes](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [helm_release.nginx_ingress](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_ingress_v1.main_alb](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/ingress_v1) | resource |
| [kubernetes_ingress_v1.main_alb](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/ingress_v1) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alb_scheme"></a> [alb\_scheme](#input\_alb\_scheme) | Scheme for the ALB (internet-facing or internal) | `string` | `"internet-facing"` | no |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | Version of the NGINX Ingress Controller Helm chart (leave null for latest) | `string` | `null` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the EKS cluster | `string` | n/a | yes |
| <a name="input_helm_depends_on"></a> [helm\_depends\_on](#input\_helm\_depends\_on) | Dependencies for the Helm release | `any` | `null` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace for NGINX Ingress Controller | `string` | `"ingress-nginx"` | no |
| <a name="input_node_security_group_id"></a> [node\_security\_group\_id](#input\_node\_security\_group\_id) | Security group ID of the EKS nodes | `string` | n/a | yes |
| <a name="input_private_subnet_ids"></a> [private\_subnet\_ids](#input\_private\_subnet\_ids) | List of private subnet IDs (not used for ALB, kept for compatibility) | `list(string)` | `[]` | no |
| <a name="input_public_subnet_ids"></a> [public\_subnet\_ids](#input\_public\_subnet\_ids) | List of public subnet IDs for the ALB | `list(string)` | n/a | yes |
| <a name="input_replica_count"></a> [replica\_count](#input\_replica\_count) | Number of NGINX Ingress Controller replicas | `number` | `2` | no |
| <a name="input_resource_limits_cpu"></a> [resource\_limits\_cpu](#input\_resource\_limits\_cpu) | CPU limit for NGINX Ingress Controller pods | `string` | `"500m"` | no |
| <a name="input_resource_limits_memory"></a> [resource\_limits\_memory](#input\_resource\_limits\_memory) | Memory limit for NGINX Ingress Controller pods | `string` | `"512Mi"` | no |
| <a name="input_resource_requests_cpu"></a> [resource\_requests\_cpu](#input\_resource\_requests\_cpu) | CPU request for NGINX Ingress Controller pods | `string` | `"100m"` | no |
| <a name="input_resource_requests_memory"></a> [resource\_requests\_memory](#input\_resource\_requests\_memory) | Memory request for NGINX Ingress Controller pods | `string` | `"90Mi"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID where the EKS cluster is deployed | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_alb_dns_name"></a> [alb\_dns\_name](#output\_alb\_dns\_name) | DNS name of the ALB created for NGINX Ingress Controller |
| <a name="output_nginx_ingress_namespace"></a> [nginx\_ingress\_namespace](#output\_nginx\_ingress\_namespace) | Namespace where NGINX Ingress Controller is installed |
| <a name="output_nginx_ingress_service_name"></a> [nginx\_ingress\_service\_name](#output\_nginx\_ingress\_service\_name) | Name of the NGINX Ingress Controller service |
<!-- END_TF_DOCS -->