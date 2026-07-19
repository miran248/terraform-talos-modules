# Talos cluster configuration

## Purpose

Generate provider-neutral Talos secrets, per-node patches, machine configurations, and client configuration from cloud pool outputs.

## Ownership

- Own cluster/node normalization, version selection, built-in IPv4/IPv6 patches, certificate SANs, host aliases, and rendered `user_data`.
- `patches/` owns the built-in common and control-plane machine configuration for each address family.

## Local Contracts

- Reject mixed address-family pools; select one complete family-specific patch set.
- Preserve patch precedence from built-in through cluster, pool, role, and node scopes.
- Use Talos document resources for settings migrated out of the legacy machine config; do not set the same subsystem in both formats.
- Never expose machine secrets or Talos client configuration as non-sensitive outputs.
- Keep outputs provider-neutral for both cloud apply modules.

## Work Guidance

- Review CNI, DNS, KubeSpan, API endpoint, and MTU interactions together when changing network patches.

## Verification

- Run `terraform fmt -check` in this directory.
- Validate all YAML documents under `patches/` when changing machine configuration.

## Child DOX Index
