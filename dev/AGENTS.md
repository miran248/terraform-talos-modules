# Development deployment

## Purpose

Exercise the modules in live IPv4 and IPv6 multi-cloud clusters spanning Scaleway control planes and Hetzner workers.

## Ownership

- Own development provider configuration, cluster compositions, test-only manifests, lockfile, operational README, and lifecycle recipes.

## Local Contracts

- Keep the IPv4 and IPv6 compositions parallel unless testing a deliberate family-specific difference.
- `1-talos-ipv6-direct.tf` owns the fail-closed KubeSpan, aggregate PodCIDR route, and pod-to-node-pool policy-routing patches used with `cilium-ipv6-direct`; keep these global Talos settings in `talos-cluster.patches.common`, and use built-in node CIDR allocation instead of an external cloud controller.
- Write Talos 1.14 patches with document resources for migrated network and Kubernetes component settings.
- Generated Terraform state, plans, Talos configs, and kubeconfigs are local artifacts and may contain secrets.
- Destructive `just apply`/`destroy` recipes affect real cloud infrastructure; do not run them merely for validation.
- Keep the `verify-ipv6-direct` just recipe self-cleaning and use it to verify Cilium, KubeSpan policy routing, worker API/DNS/NAT64 access, and Gateway API before destroying the IPv6 direct-routing cluster.

## Work Guidance

- Use development configurations to exercise public module interfaces, not to hide module defaults.

## Verification

- Run `terraform fmt -check` in this directory.
- Run `terraform validate` only after initialization and without applying infrastructure.
- Run `just verify-ipv6-direct` against the live IPv6 direct-routing development cluster before release or teardown.

## Child DOX Index
