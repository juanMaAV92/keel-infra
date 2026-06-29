# Module contract

## Why a contract instead of "generic" modules

Terraform has **no cross-cloud abstraction**. `aws_vpc`, `google_compute_network` and
`azurerm_virtual_network` are unrelated resource types with different schemas and mental
models. A single module that branches on a `cloud` variable (`count = var.cloud == "aws"`)
becomes unreadable and fragile — a known anti-pattern.

Instead, keel-infra abstracts the way Steer does in Go: **a stable interface, with one
implementation per backend.** Here the "interface" is a *contract* — the input variables a
concept accepts and the outputs it guarantees. Each cloud implements that contract in its
own subdirectory. Swapping clouds means pointing at a different implementation folder, not
rewriting the composition above it.

## Layout

Concept is the first-class citizen; cloud is an implementation detail beneath it:

```
modules/
  <concept>/
    README.md        # documents THIS concept's contract (inputs + outputs)
    aws/             # AWS implementation (V1)
    gcp/             # (future) GCP implementation — same contract
    azure/           # (future) Azure implementation — same contract
```

All implementations of a concept **must** accept the same input variable names and expose
the same output names. That sameness is the whole point: it's what lets a composition stay
cloud-neutral.

## V1 concepts

| Concept        | Purpose                                  | AWS implementation (planned) |
| -------------- | ---------------------------------------- | ---------------------------- |
| `network`      | VPC/VNet, subnets, routing, egress       | `aws_vpc` + subnets + NAT toggle |
| `cluster`      | Container orchestration cluster          | `aws_ecs_cluster`            |
| `service`      | A deployed containerized service         | `aws_ecs_service` + task def |
| `loadbalancer` | L7 ingress + routing                     | `aws_lb` + listener          |
| `registry`     | Container image registry                 | `aws_ecr_repository`         |
| `iam`          | Roles/policies for the above             | `aws_iam_role` + policies    |

## Contract conventions

Until each module's own README is written, these baseline rules apply to every concept:

### Common inputs (every module accepts)

| Variable       | Type          | Purpose                                  |
| -------------- | ------------- | ---------------------------------------- |
| `project_name` | `string`      | Project slug — first token in names      |
| `environment`  | `string`      | Environment slug — second token in names |
| `common_tags`  | `map(string)` | Caller tags, merged with module tags     |

Resource names are always derived as `${project_name}-${environment}-<name>`
(see [`naming.md`](naming.md)). Optional behavior is gated behind `enable_*` boolean
variables defaulting to safe values — never hardcoded.

### Common outputs (every module exposes)

- The primary resource **id** and **arn/self_link** of what it created.
- Any identifier a *downstream* concept needs to reference it (e.g. `network` exposes
  `vpc_id` and `private_subnet_ids` that `service` consumes).

Outputs are the contract's public surface — naming them consistently across clouds is what
keeps compositions portable.

### Quality bar (per module, when implemented)

- A `README.md` documenting every input and output (generated with `terraform-docs`).
- At least one native `terraform test` (`*.tftest.hcl`) covering the default path.
- Passes `terraform fmt`, `tflint`, and `trivy config` with no CRITICAL/HIGH findings.
