# Plan-level tests for registry/aws. Offline (mocked provider), focused on repository
# fan-out, secure defaults, and the lifecycle-policy toggle.
# Run: terraform test  (from modules/registry/aws)

mock_provider "aws" {}

variables {
  project_name     = "acme"
  environment      = "stg"
  repository_names = ["api", "web"]
}

run "creates_one_repo_per_image" {
  command = plan

  assert {
    condition     = length(aws_ecr_repository.this) == 2
    error_message = "Should create one ECR repository per image name."
  }

  assert {
    condition     = aws_ecr_repository.this["api"].name == "acme/api"
    error_message = "Repository should be namespaced as <project>/<image>."
  }
}

run "secure_defaults" {
  command = plan

  assert {
    condition     = aws_ecr_repository.this["api"].image_tag_mutability == "IMMUTABLE"
    error_message = "Tags should be immutable by default."
  }

  assert {
    condition     = aws_ecr_repository.this["api"].image_scanning_configuration[0].scan_on_push == true
    error_message = "Scan-on-push should be enabled by default."
  }

  assert {
    condition     = length(aws_ecr_lifecycle_policy.this) == 2
    error_message = "A lifecycle policy should be attached to each repository by default."
  }
}

run "lifecycle_policy_can_be_disabled" {
  command = plan

  variables {
    enable_lifecycle_policy = false
  }

  assert {
    condition     = length(aws_ecr_lifecycle_policy.this) == 0
    error_message = "Disabling the lifecycle policy should attach none."
  }
}

run "kms_encryption_opt_in" {
  command = plan

  variables {
    encryption_type = "KMS"
  }

  assert {
    condition     = aws_ecr_repository.this["api"].encryption_configuration[0].encryption_type == "KMS"
    error_message = "encryption_type should propagate to the repository."
  }
}
