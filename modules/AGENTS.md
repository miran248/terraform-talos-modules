# Terraform modules

## Purpose

Reusable modules provision cloud capacity, generate Talos configurations, create machines, bootstrap clusters, and configure optional workload identity.

## Ownership

- Each immediate child module owns its Terraform provider constraints, variables, resources/data sources, outputs, and README.
- Public module interfaces are the typed variables and outputs. Callers compose pool → cluster/apply → bootstrap flows.

## Local Contracts

- Keep input types and validations aligned with the shapes consumed across modules.
- Treat renamed/removed variables, output fields, resources, and changed defaults as compatibility-sensitive changes.
- Keep each module README synchronized with inputs, outputs, ordering constraints, and examples.
- Preserve sensitive markings for credentials, machine secrets, and client configuration.

## Work Guidance

- Format changed Terraform with `terraform fmt`.
- Avoid provider-specific assumptions in `talos-cluster`; encode them in pool/apply modules.
- Update repository examples and release-reference links when a public interface changes.

## Verification

- Run `terraform fmt -check -recursive modules`.
- Run `terraform validate` from an initialized caller or module directory when provider availability permits.

## Child DOX Index

- [hcloud-pool/AGENTS.md](hcloud-pool/AGENTS.md) — Hetzner capacity allocation
- [hcloud-apply/AGENTS.md](hcloud-apply/AGENTS.md) — Hetzner servers and firewalls
- [scaleway-pool/AGENTS.md](scaleway-pool/AGENTS.md) — Scaleway capacity allocation
- [scaleway-apply/AGENTS.md](scaleway-apply/AGENTS.md) — Scaleway servers, volumes, and security groups
- [scaleway-image/AGENTS.md](scaleway-image/AGENTS.md) — Scaleway image registration
- [talos-cluster/AGENTS.md](talos-cluster/AGENTS.md) — provider-neutral Talos configuration generation
- [talos-apply/AGENTS.md](talos-apply/AGENTS.md) — Talos application, bootstrap, and upgrades
- [gcp-wif/AGENTS.md](gcp-wif/AGENTS.md) — GCP workload identity resources
- [gcp-wif-apply/AGENTS.md](gcp-wif-apply/AGENTS.md) — cluster OIDC publication
