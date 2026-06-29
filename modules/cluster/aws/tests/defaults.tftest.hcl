# Plan-level tests for cluster/aws. Offline (mocked provider), focused on naming,
# capacity-provider registration, and the Container Insights toggle.
# Run: terraform test  (from modules/cluster/aws)

mock_provider "aws" {}

variables {
  project_name = "acme"
  environment  = "stg"
}

run "naming_and_defaults" {
  command = plan

  assert {
    condition     = aws_ecs_cluster.this.name == "acme-stg-cluster"
    error_message = "Cluster name should follow <project>-<env>-cluster."
  }

  assert {
    condition     = length(aws_ecs_cluster_capacity_providers.this.capacity_providers) == 2 && contains(aws_ecs_cluster_capacity_providers.this.capacity_providers, "FARGATE_SPOT")
    error_message = "Both FARGATE and FARGATE_SPOT should be registered by default."
  }

  assert {
    condition     = one([for s in aws_ecs_cluster.this.setting : s.value if s.name == "containerInsights"]) == "enabled"
    error_message = "Container Insights should be enabled by default."
  }
}

run "container_insights_can_be_disabled" {
  command = plan

  variables {
    enable_container_insights = false
  }

  assert {
    condition     = one([for s in aws_ecs_cluster.this.setting : s.value if s.name == "containerInsights"]) == "disabled"
    error_message = "Disabling Container Insights should set the cluster setting to disabled."
  }
}

run "capacity_providers_are_configurable" {
  command = plan

  variables {
    capacity_providers = ["FARGATE"]
  }

  assert {
    condition     = length(aws_ecs_cluster_capacity_providers.this.capacity_providers) == 1 && contains(aws_ecs_cluster_capacity_providers.this.capacity_providers, "FARGATE")
    error_message = "Only the requested capacity providers should be registered."
  }
}
