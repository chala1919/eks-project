output "karpenter_controller_role_arn" {
  description = "ARN of the Karpenter controller IAM role"
  value       = aws_iam_role.karpenter_controller.arn
}

output "karpenter_node_role_arn" {
  description = "ARN of the Karpenter node IAM role"
  value       = aws_iam_role.karpenter_node.arn
}

output "karpenter_node_instance_profile_name" {
  description = "Name of the Karpenter node instance profile"
  value       = aws_iam_instance_profile.karpenter_node.name
}

output "karpenter_interruption_queue_arn" {
  description = "ARN of the Karpenter interruption SQS queue"
  value       = aws_sqs_queue.karpenter_interruption.arn
}

output "helm_release" {
  description = "Karpenter Helm release resource"
  value       = helm_release.karpenter
}

