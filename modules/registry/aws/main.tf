# ============================================
# registry/aws — container image registry (ECR)
# ============================================
# AWS implementation of the `registry` concept. One aws_ecr_repository per image name
# (AWS granularity is one repository = one image), created with for_each. Follows the
# pattern set by network/aws. See docs/contract.md.

locals {
  module_tags = merge(var.common_tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Module      = "registry"
  })

  # Namespaced repository name: <project>/<image>. Env is intentionally not in the name —
  # the same image is promoted across environments.
  repositories = { for name in var.repository_names : name => "${var.project_name}/${name}" }
}

resource "aws_ecr_repository" "this" {
  for_each = local.repositories

  name                 = each.value
  image_tag_mutability = var.image_tag_mutability
  force_delete         = var.force_delete

  image_scanning_configuration {
    scan_on_push = var.enable_scan_on_push
  }

  encryption_configuration {
    encryption_type = var.encryption_type
    # kms_key is only meaningful for KMS; null falls back to the AWS-managed key.
    kms_key = var.encryption_type == "KMS" ? var.kms_key_arn : null
  }

  tags = merge(local.module_tags, { Name = each.value })
}

resource "aws_ecr_lifecycle_policy" "this" {
  for_each = var.enable_lifecycle_policy ? local.repositories : {}

  repository = aws_ecr_repository.this[each.key].name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep only the most recent ${var.max_image_count} images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = var.max_image_count
      }
      action = { type = "expire" }
    }]
  })
}
