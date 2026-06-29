# ============================================
# cluster/aws — outputs (the cluster concept's contract surface)
# ============================================
# The service module references the cluster by id/name.

output "cluster_id" {
  description = "ID of the ECS cluster."
  value       = aws_ecs_cluster.this.id
}

output "cluster_arn" {
  description = "ARN of the ECS cluster."
  value       = aws_ecs_cluster.this.arn
}

output "cluster_name" {
  description = "Name of the ECS cluster (<project>-<env>-cluster)."
  value       = aws_ecs_cluster.this.name
}

output "capacity_providers" {
  description = "Capacity providers registered on the cluster."
  value       = aws_ecs_cluster_capacity_providers.this.capacity_providers
}
