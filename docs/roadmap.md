# Roadmap

V1 targets AWS. Modules ship **complete** — HCL + README (terraform-docs) + at least one
`terraform test` — before the next one starts. Order follows the dependency graph: nothing
is built before the outputs it consumes exist.

> **On identity (IAM).** There is no top-level `iam` concept. "IAM" is an AWS name; the
> shared idea — *a workload identity plus scoped permissions* — is modeled differently in
> each cloud (AWS role + policy, GCP service account + bindings, Azure managed identity +
> RBAC). Identity is also cross-cutting: it belongs with the resource it protects. So each
> module **owns its own identity** (e.g. `service/aws` creates its task role and exposes
> `identity_ref`). A standalone `identity` concept is added **only if** genuinely shared
> identities appear (e.g. a common execution role or a CI deploy role).

## Phases

### Phase 0 — Skeleton ✅
Structure, naming convention, module contract, CI (OIDC), license. *(done)*

### Phase 1 — `network/aws` (reference module) 🔑 ✅
The keystone. Foundation for everything (VPC, subnets, routing, egress) **and** the pattern
every later module copies: `main/variables/outputs/versions`, terraform-docs README, first
`terraform test`, the contract made real. Activates CI on real HCL. Closes the nao-infra gap
with an explicit `enable_nat_gateway` / S3-endpoint toggle.
*Size: medium. Blocks all others.* **Done** — single/per-AZ NAT toggle, configurable flow-log
retention, scoped (non-`*`) flow-logs IAM, optional S3 gateway endpoint; 4 passing offline tests.

### Phase 2 — `registry/aws`
Independent, no dependencies (`aws_ecr_repository`). Validates the pattern on a second,
simple module before the complex one.
*Size: small.*

### Phase 3 — `cluster/aws`
ECS cluster + capacity providers (FARGATE / FARGATE_SPOT). Depends conceptually on `network`.
*Size: small.*

### Phase 4 — `loadbalancer/aws`
ALB + listener + security group. Consumes `network`. The ingress `service` plugs into.
*Size: medium.*

### Phase 5 — `service/aws` (capstone) ⭐
ECS service + task definition. Consumes `network`, `cluster`, `registry`, `loadbalancer`,
and **owns its identity** (task role → `identity_ref` output). Maps most directly to Steer
(Steer deploys *services*). Ports the proven bits of nao-infra, genericized: autoscaling,
deployment circuit breaker + rollback, logging driver toggle, `ignore_changes` on
`desired_count`.
*Size: large. The most important module in the repo.*

### Phase 6 — `environments/aws-example`
Wires the modules into an applyable composition. Proves the contract end-to-end and is the
portfolio demo.

### Phase 7 — Steer integration validation 🔗
Point a `steer.toml` at the names keel-infra produces; confirm Steer discovers and deploys
onto the substrate. Closes the loop between the two repos — the story that sells the
ecosystem.

### Phase 8 — Multi-cloud seam (later, optional)
First non-AWS implementation of one concept (`network/gcp`) to prove the contract holds
across clouds. Only once Steer supports that provider.

## Dependency graph

```
network ──┬──> cluster ──┐
          ├──> loadbalancer ──> service (owns identity)
          └────────────────────^
registry ──────────────────────^
```
