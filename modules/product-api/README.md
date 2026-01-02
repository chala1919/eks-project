# Bastion Host Module

This module creates a bastion host that provides secure access to product data stored in S3.

## Architecture

- **Bastion Host**: EC2 instance in public subnet with IAM role to access S3
- **S3 Access**: Restricted bucket policy allows only:
  - Bastion host (read-only)
  - EKS node groups (read-only)
  - Dagster pods (read/write)

## Usage

### SSH to Bastion Host

```bash
ssh ec2-user@<bastion-public-ip>
```

### Fetch Product Data

Once on the bastion host, run:

```bash
/home/ec2-user/fetch-products.sh
```

This script will:
1. List all files in the S3 bucket
2. Download all files with prefix `data_`
3. Display the content of each file
4. Save files to `/home/ec2-user/products/`

### Manual S3 Access

You can also use AWS CLI directly:

```bash
# List all files
aws s3 ls s3://<bucket-name>/

# Download a specific file
aws s3 cp s3://<bucket-name>/data_20240101_120000.json /tmp/

# View file content
aws s3 cp s3://<bucket-name>/data_20240101_120000.json - | jq .
```

## Security

- S3 bucket policy restricts access to bastion host and EKS nodes only
- Bastion host has IAM role with S3 read permissions
- All access is logged via CloudTrail


<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_instance_profile.bastion](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_role.bastion](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.bastion_s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.bastion_ssm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_instance.bastion](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_security_group.bastion](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_ami.amazon_linux_2023](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_allowed_cidr_blocks"></a> [allowed\_cidr\_blocks](#input\_allowed\_cidr\_blocks) | CIDR blocks allowed to SSH to bastion host | `list(string)` | <pre>[<br/>  "0.0.0.0/0"<br/>]</pre> | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region | `string` | `"eu-west-1"` | no |
| <a name="input_bastion_instance_type"></a> [bastion\_instance\_type](#input\_bastion\_instance\_type) | EC2 instance type for bastion host | `string` | `"t3.micro"` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Prefix for resource names | `string` | n/a | yes |
| <a name="input_private_subnet_ids"></a> [private\_subnet\_ids](#input\_private\_subnet\_ids) | Private subnet IDs (not used, kept for compatibility) | `list(string)` | n/a | yes |
| <a name="input_public_subnet_ids"></a> [public\_subnet\_ids](#input\_public\_subnet\_ids) | Public subnet IDs for bastion host | `list(string)` | n/a | yes |
| <a name="input_s3_bucket_name"></a> [s3\_bucket\_name](#input\_s3\_bucket\_name) | Name of the S3 bucket containing product data | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to resources | `map(string)` | `{}` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID where resources will be deployed | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_bastion_instance_id"></a> [bastion\_instance\_id](#output\_bastion\_instance\_id) | Instance ID of the bastion host |
| <a name="output_bastion_public_ip"></a> [bastion\_public\_ip](#output\_bastion\_public\_ip) | Public IP address of the bastion host |
| <a name="output_bastion_role_arn"></a> [bastion\_role\_arn](#output\_bastion\_role\_arn) | IAM role ARN of the bastion host |
<!-- END_TF_DOCS -->