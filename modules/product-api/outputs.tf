output "bastion_public_ip" {
  description = "Public IP address of the bastion host"
  value       = aws_instance.bastion.public_ip
}

output "bastion_instance_id" {
  description = "Instance ID of the bastion host"
  value       = aws_instance.bastion.id
}

output "bastion_role_arn" {
  description = "IAM role ARN of the bastion host"
  value       = aws_iam_role.bastion.arn
}
