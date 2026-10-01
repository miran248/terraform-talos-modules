# Talos cluster configuration

Generate provider-neutral secrets, patches, machine configurations, and sensitive client configuration. Own certificate SANs, host aliases, rendered `user_data`, and cluster/node normalization. `patches/` owns the built-in common and control-plane machine configuration for each address family. Reject mixed-family pools and preserve patch precedence: built-in → cluster → pool → role → node.

Use Talos document resources for migrated settings, never duplicate a subsystem in legacy configuration, and let Talos select API-server advertise addresses. Built-in IPv6 KubeSpan advertises only IPv6 peers.

Read [networking contracts](../../docs/maintenance/networking.md) before network changes. Run `terraform fmt -check` here and parse changed YAML under `patches/`.
