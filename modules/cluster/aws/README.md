# cluster/aws

AWS implementation of the `cluster` concept: an **ECS cluster** — the compute environment
that services are deployed into.

This module is intentionally **thin**. It creates the cluster and registers the Fargate
capacity providers (`FARGATE`, `FARGATE_SPOT`), but it does **not** choose a spot-vs-on-demand
strategy — that is a per-service decision and lives in the service module. See
[`docs/contract.md`](../../../docs/contract.md).

## Cross-cloud note

The `cluster` concept maps to ECS here and to an Azure Container Apps environment, but
**Cloud Run has no cluster** — a future `cluster/gcp` would be a near-empty passthrough.
`FARGATE_SPOT` is AWS-specific (discounted interruptible capacity); pure-serverless runtimes
have no spot equivalent. See [`docs/roadmap.md`](../../../docs/roadmap.md).

## Usage

```hcl
module "cluster" {
  source = "github.com/juanMaAV92/keel-infra//modules/cluster/aws"

  project_name = "acme"
  environment  = "stg"

  capacity_providers        = ["FARGATE", "FARGATE_SPOT"]
  enable_container_insights = true
}

# A service references it:
#   cluster_id   = module.cluster.cluster_id
#   cluster_name = module.cluster.cluster_name
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
| [aws_ecs_cluster.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster) | resource |
| [aws_ecs_cluster_capacity_providers.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster_capacity_providers) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_capacity_providers"></a> [capacity\_providers](#input\_capacity\_providers) | Fargate capacity providers to register on the cluster. Services pick their own strategy across these (see the service module). | `list(string)` | <pre>[<br/>  "FARGATE",<br/>  "FARGATE_SPOT"<br/>]</pre> | no |
| <a name="input_common_tags"></a> [common\_tags](#input\_common\_tags) | Tags merged into every resource, on top of the module's baseline tags. | `map(string)` | `{}` | no |
| <a name="input_enable_container_insights"></a> [enable\_container\_insights](#input\_enable\_container\_insights) | Enable CloudWatch Container Insights for the cluster (extra metrics; incurs cost). | `bool` | `true` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment slug — the second token in the cluster name (e.g. stg, prod). | `string` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project slug — the first token in the cluster name (<project>-<env>-cluster). | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_capacity_providers"></a> [capacity\_providers](#output\_capacity\_providers) | Capacity providers registered on the cluster. |
| <a name="output_cluster_arn"></a> [cluster\_arn](#output\_cluster\_arn) | ARN of the ECS cluster. |
| <a name="output_cluster_id"></a> [cluster\_id](#output\_cluster\_id) | ID of the ECS cluster. |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | Name of the ECS cluster (<project>-<env>-cluster). |
<!-- END_TF_DOCS -->
