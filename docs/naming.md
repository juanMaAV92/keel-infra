# Naming convention

keel-infra and [Steer](https://github.com/juanMaAV92/steer) share one naming convention.
This is the glue between the two tools: keel-infra **creates** resources with these names,
and Steer **finds** them by reading the same templates from `steer.toml`. If the names
don't line up, Steer can't operate the substrate keel-infra built.

## The pattern

Every named resource follows:

```
${project}-${environment}-${name}
```

| Token          | Meaning                                  | Example     |
| -------------- | ---------------------------------------- | ----------- |
| `project`      | Short slug for the whole platform/org    | `acme`      |
| `environment`  | Deployment environment                   | `stg`, `prod` |
| `name`         | The specific resource within a concept   | `api`, `web` |

Examples:

- ECS cluster: `acme-prod-cluster`
- ECS service: `acme-prod-api`
- ECR repository: `acme-api`  *(registries are usually environment-agnostic — see below)*

## Mapping to `steer.toml`

Steer derives resource names from templates. keel-infra must produce names that match the
template a user sets there. Steer's design uses templates such as:

```toml
cluster_template = "{env}-cluster"
service_template = "{env}-{service}"
```

Recommended alignment:

| Steer template token | keel-infra token     |
| -------------------- | -------------------- |
| `{env}`              | `${environment}`     |
| `{service}`          | `${name}` (service)  |
| project prefix       | `${project}`         |

> **Convention over coupling.** The two repos are not linked by code — only by this
> agreed-upon string format. Keep this document and `steer.toml` templates in sync; treat a
> change here as a breaking change for any Steer install pointing at the substrate.

## Tagging

Independently of names, every resource carries a baseline tag set so cost and ownership are
queryable:

| Tag           | Value                          |
| ------------- | ------------------------------ |
| `Project`     | `${project}`                   |
| `Environment` | `${environment}`               |
| `ManagedBy`   | `Terraform`                    |
| `Module`      | The concept (e.g. `network`)   |

Modules merge these with any caller-supplied `common_tags`.
