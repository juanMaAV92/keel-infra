# ============================================
# cluster/aws — input variables
# ============================================
# Common contract inputs (every keel-infra module accepts these). See docs/contract.md.

variable "project_name" {
  description = "Project slug — the first token in the cluster name (<project>-<env>-cluster)."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*$", var.project_name))
    error_message = "project_name must be lowercase alphanumeric with hyphens, starting with a letter."
  }
}

variable "environment" {
  description = "Environment slug — the second token in the cluster name (e.g. stg, prod)."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*$", var.environment))
    error_message = "environment must be lowercase alphanumeric with hyphens, starting with a letter."
  }
}

variable "common_tags" {
  description = "Tags merged into every resource, on top of the module's baseline tags."
  type        = map(string)
  default     = {}
}

# ----- Cluster-specific inputs -----

variable "capacity_providers" {
  description = "Fargate capacity providers to register on the cluster. Services pick their own strategy across these (see the service module)."
  type        = list(string)
  default     = ["FARGATE", "FARGATE_SPOT"]

  validation {
    condition     = length(var.capacity_providers) > 0 && alltrue([for cp in var.capacity_providers : contains(["FARGATE", "FARGATE_SPOT"], cp)])
    error_message = "capacity_providers may only contain FARGATE and/or FARGATE_SPOT."
  }
}

variable "enable_container_insights" {
  description = "Enable CloudWatch Container Insights for the cluster (extra metrics; incurs cost)."
  type        = bool
  default     = true
}
