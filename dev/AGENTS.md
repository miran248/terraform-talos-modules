# Development deployment

## Purpose

Exercise the modules in live IPv4 and IPv6 multi-cloud clusters spanning Scaleway control planes and Hetzner workers.

## Ownership

- Own development provider configuration, cluster compositions, test-only manifests, lockfile, operational README, and lifecycle recipes.

## Local Contracts

- Keep the IPv4 and IPv6 compositions parallel unless testing a deliberate family-specific difference.
- `1-talos-ipv6-direct.tf` owns the fail-closed KubeSpan patches used with `cilium-ipv6-direct`; its pool installs the main-table KubeSpan route for the module's predefined Pod CIDR, and built-in node CIDR allocation avoids an external cloud controller.
- Write Talos 1.14 patches with document resources for migrated network and Kubernetes component settings.
- Generated Terraform state, plans, Talos configs, and kubeconfigs are local artifacts and may contain secrets.
- Destructive `just apply`/`destroy` recipes affect real cloud infrastructure; do not run them merely for validation.

## Work Guidance

- Use development configurations to exercise public module interfaces, not to hide module defaults.

## Verification

- Run `terraform fmt -check` in this directory.
- Run `terraform validate` only after initialization and without applying infrastructure.

## Child DOX Index
