# ============================================
# registry/aws — input variables
# ============================================
# Common contract inputs (every keel-infra module accepts these). See docs/contract.md.

variable "project_name" {
  description = "Project slug — used to namespace repositories (<project>/<image>)."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*$", var.project_name))
    error_message = "project_name must be lowercase alphanumeric with hyphens, starting with a letter."
  }
}

variable "environment" {
  description = "Environment slug. ECR repositories are shared across environments, so this is recorded in tags, not in the repository name."
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

# ----- Registry-specific inputs -----

variable "repository_names" {
  description = "Short image names to host (e.g. [\"api\", \"web\"]). Each becomes an ECR repository named <project>/<name>."
  type        = list(string)

  validation {
    condition     = length(var.repository_names) > 0
    error_message = "Provide at least one repository name."
  }

  validation {
    condition     = alltrue([for n in var.repository_names : can(regex("^[a-z0-9]+([._/-][a-z0-9]+)*$", n))])
    error_message = "Each repository name must be lowercase and may contain . _ - / between alphanumeric segments."
  }
}

variable "image_tag_mutability" {
  description = "IMMUTABLE prevents overwriting a pushed tag (recommended); MUTABLE allows it."
  type        = string
  default     = "IMMUTABLE"

  validation {
    condition     = contains(["IMMUTABLE", "MUTABLE"], var.image_tag_mutability)
    error_message = "image_tag_mutability must be IMMUTABLE or MUTABLE."
  }
}

variable "enable_scan_on_push" {
  description = "Scan images for vulnerabilities automatically on push."
  type        = bool
  default     = true
}

variable "force_delete" {
  description = "Allow deleting a repository that still contains images (useful for ephemeral environments)."
  type        = bool
  default     = false
}

variable "encryption_type" {
  description = "Encryption at rest: AES256 (S3-managed) or KMS."
  type        = string
  default     = "AES256"

  validation {
    condition     = contains(["AES256", "KMS"], var.encryption_type)
    error_message = "encryption_type must be AES256 or KMS."
  }
}

variable "kms_key_arn" {
  description = "Customer-managed KMS key ARN. Only used when encryption_type is KMS; null uses the AWS-managed key."
  type        = string
  default     = null
}

variable "enable_lifecycle_policy" {
  description = "Attach a lifecycle policy that expires old images to control storage cost."
  type        = bool
  default     = true
}

variable "max_image_count" {
  description = "When the lifecycle policy is enabled, keep at most this many images per repository."
  type        = number
  default     = 10

  validation {
    condition     = var.max_image_count >= 1
    error_message = "max_image_count must be at least 1."
  }
}
