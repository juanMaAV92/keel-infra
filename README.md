<h1 align="center">⚓ keel-infra</h1>

<p align="center">
  <b>The foundation your <a href="https://github.com/juanMaAV92/steer">Steer</a> sails on.</b><br>
  An opinionated Terraform scaffold that provisions the cloud substrate — so anyone can take it and start.
</p>

<p align="center">
  <a href="LICENSE"><img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-blue.svg"></a>
  <img alt="Status" src="https://img.shields.io/badge/status-WIP-orange.svg">
  <img alt="IaC" src="https://img.shields.io/badge/built%20with-Terraform-7B42BC.svg">
</p>

---

> ⚠️ **Work in progress.** This is the project skeleton. The structure, naming convention
> and module contract are settled (see [`docs/`](docs)); module implementations come next.

## What is keel-infra?

The keel is the structural backbone of a ship — everything is built on it. **keel-infra**
provisions the cloud substrate (network, container cluster, load balancer, registry, IAM…)
that a platform tool like [**Steer**](https://github.com/juanMaAV92/steer) then deploys onto.

```
keel-infra   +   steer
(provisions)     (deploys)
   the base        the apps
```

Steer is intentionally decoupled from any concrete infrastructure — it reads names from
`steer.toml` and assumes the substrate already exists. keel-infra is the missing half: the
opinionated, reusable foundation that creates that substrate, following the **same naming
convention** Steer expects. See [`docs/naming.md`](docs/naming.md).

## Who is it for?

The same audience as Steer: **small teams with one person who owns the cloud setup** and
others who just want to ship. The cloud owner runs keel-infra once to lay the foundation,
then hands the keys to Steer.

## Design principles

- **Contract first, implementation per cloud.** Terraform has no cross-cloud resource
  abstraction, so there is no "generic" module. Instead, each *concept* (network, cluster,
  service…) defines one canonical contract — its input variables and outputs — and each
  cloud provides an implementation behind that contract. AWS is the V1 target; the seam for
  GCP/Azure is visible but unbuilt. See [`docs/contract.md`](docs/contract.md).
- **Opinionated, not exhaustive.** Only generic, reusable capabilities. Anything that
  depends on a proprietary setup stays out.
- **Quality bar from day one.** Per-module docs, native `terraform test`, `tflint`, and a
  CI that authenticates via GitHub OIDC — no long-lived credentials.

## Planned layout

```
keel-infra/
├── docs/
│   ├── naming.md        # naming convention ↔ steer.toml templates
│   ├── contract.md      # canonical input/output contract per concept
│   └── roadmap.md       # what's next, in dependency order
├── modules/             # (coming) modules/<concept>/<cloud>/ — e.g. network/aws/
└── environments/        # (coming) example compositions per cloud
```

Concepts targeted for V1: `network`, `registry`, `cluster`, `loadbalancer`, `service`.
Identity (IAM) is **not** a peer concept — each module owns its own identity, because the
shared idea is modeled too differently across clouds to share one contract. See
[`docs/roadmap.md`](docs/roadmap.md).

## Status & roadmap

- [x] Repo skeleton: structure, naming convention, module contract, CI, license
- [x] `network/aws` — reference module (sets the pattern) with README + `terraform test`
- [x] `registry/aws` — ECR repositories (secure defaults, lifecycle retention)
- [ ] `cluster/aws`, `loadbalancer/aws`
- [ ] `service/aws` — capstone (owns its identity)
- [ ] `environments/aws-example` end-to-end composition
- [ ] Steer integration validation (a `steer.toml` driving the substrate)
- [ ] Multi-cloud seam: first non-AWS implementation (tracks Steer's provider support)

Full detail and dependency graph: [`docs/roadmap.md`](docs/roadmap.md).

## License

[MIT](LICENSE) © 2026 juanMaAV92 (Juan Manuel Armero Viveros)
