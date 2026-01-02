output "wait_for_cluster_id" {
  description = "ID of the wait resource (for dependencies)"
  value       = time_sleep.wait_for_cluster.id
}

