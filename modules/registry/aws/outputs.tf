# ============================================
# registry/aws — outputs (the registry concept's contract surface)
# ============================================
# `repository_urls` is what a service (or Steer) needs to pull an image.

output "repository_urls" {
  description = "Map of short image name to its repository URL (the push/pull address)."
  value       = { for name, repo in aws_ecr_repository.this : name => repo.repository_url }
}

output "repository_arns" {
  description = "Map of short image name to repository ARN."
  value       = { for name, repo in aws_ecr_repository.this : name => repo.arn }
}

output "repository_names" {
  description = "Map of short image name to full ECR repository name (<project>/<image>)."
  value       = { for name, repo in aws_ecr_repository.this : name => repo.name }
}

output "registry_id" {
  description = "ECR registry (AWS account) ID hosting the repositories."
  # All repositories share the same registry (the account), so any one will do.
  value = try(values(aws_ecr_repository.this)[0].registry_id, null)
}
