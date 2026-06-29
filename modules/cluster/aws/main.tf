# ============================================
# cluster/aws — ECS cluster + capacity providers
# ============================================
# AWS implementation of the `cluster` concept: a thin compute environment that services
# are deployed into. It registers the Fargate capacity providers but does NOT choose a
# spot-vs-on-demand strategy — that is a per-service decision (see the service module).
# Follows the pattern set by network/aws. See docs/contract.md.

locals {
  # Matches the naming convention and Steer's {env}-cluster template (see docs/naming.md).
  cluster_name = "${var.project_name}-${var.environment}-cluster"

  module_tags = merge(var.common_tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Module      = "cluster"
  })
}

resource "aws_ecs_cluster" "this" {
  name = local.cluster_name

  setting {
    name  = "containerInsights"
    value = var.enable_container_insights ? "enabled" : "disabled"
  }

  tags = merge(local.module_tags, { Name = local.cluster_name })
}

resource "aws_ecs_cluster_capacity_providers" "this" {
  cluster_name       = aws_ecs_cluster.this.name
  capacity_providers = var.capacity_providers
}
