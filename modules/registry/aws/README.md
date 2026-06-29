# registry/aws

AWS implementation of the `registry` concept: container image repositories on **ECR**.

AWS granularity is one repository per image, so this module takes a list of image names and
creates one `aws_ecr_repository` each (namespaced as `<project>/<image>`). Secure defaults:
immutable tags, scan-on-push, and a lifecycle policy that caps stored images. See
[`docs/contract.md`](../../../docs/contract.md).

## Naming

ECR repositories are **shared across environments** — you build an image once and promote
the same artifact through `stg` → `prod`. So `environment` is recorded in tags, not in the
repository name. Repository names are `<project>/<image>` (e.g. `acme/api`).

## Usage

```hcl
module "registry" {
  source = "github.com/juanMaAV92/keel-infra//modules/registry/aws"

  project_name     = "acme"
  environment      = "stg"
  repository_names = ["api", "web"]

  image_tag_mutability = "IMMUTABLE"
  enable_scan_on_push  = true
  max_image_count      = 10
}

# A service consumes the URL:
#   image = "${module.registry.repository_urls["api"]}:v1.2.3"
```

## Testing

```bash
terraform init
terraform test   # offline plan-level tests (mocked provider, no credentials)
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0, < 6.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.100.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_ecr_lifecycle_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_lifecycle_policy) | resource |
| [aws_ecr_repository.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_common_tags"></a> [common\_tags](#input\_common\_tags) | Tags merged into every resource, on top of the module's baseline tags. | `map(string)` | `{}` | no |
| <a name="input_enable_lifecycle_policy"></a> [enable\_lifecycle\_policy](#input\_enable\_lifecycle\_policy) | Attach a lifecycle policy that expires old images to control storage cost. | `bool` | `true` | no |
| <a name="input_enable_scan_on_push"></a> [enable\_scan\_on\_push](#input\_enable\_scan\_on\_push) | Scan images for vulnerabilities automatically on push. | `bool` | `true` | no |
| <a name="input_encryption_type"></a> [encryption\_type](#input\_encryption\_type) | Encryption at rest: AES256 (S3-managed) or KMS. | `string` | `"AES256"` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment slug. ECR repositories are shared across environments, so this is recorded in tags, not in the repository name. | `string` | n/a | yes |
| <a name="input_force_delete"></a> [force\_delete](#input\_force\_delete) | Allow deleting a repository that still contains images (useful for ephemeral environments). | `bool` | `false` | no |
| <a name="input_image_tag_mutability"></a> [image\_tag\_mutability](#input\_image\_tag\_mutability) | IMMUTABLE prevents overwriting a pushed tag (recommended); MUTABLE allows it. | `string` | `"IMMUTABLE"` | no |
| <a name="input_kms_key_arn"></a> [kms\_key\_arn](#input\_kms\_key\_arn) | Customer-managed KMS key ARN. Only used when encryption\_type is KMS; null uses the AWS-managed key. | `string` | `null` | no |
| <a name="input_max_image_count"></a> [max\_image\_count](#input\_max\_image\_count) | When the lifecycle policy is enabled, keep at most this many images per repository. | `number` | `10` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project slug — used to namespace repositories (<project>/<image>). | `string` | n/a | yes |
| <a name="input_repository_names"></a> [repository\_names](#input\_repository\_names) | Short image names to host (e.g. ["api", "web"]). Each becomes an ECR repository named <project>/<name>. | `list(string)` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_registry_id"></a> [registry\_id](#output\_registry\_id) | ECR registry (AWS account) ID hosting the repositories. |
| <a name="output_repository_arns"></a> [repository\_arns](#output\_repository\_arns) | Map of short image name to repository ARN. |
| <a name="output_repository_names"></a> [repository\_names](#output\_repository\_names) | Map of short image name to full ECR repository name (<project>/<image>). |
| <a name="output_repository_urls"></a> [repository\_urls](#output\_repository\_urls) | Map of short image name to its repository URL (the push/pull address). |
<!-- END_TF_DOCS -->
