# Talos cluster configuration

Generate provider-neutral secrets, patches, machine configurations, and sensitive client configuration. Reject mixed-family pools and preserve patch precedence: built-in → cluster → pool → role → node.

Use Talos document resources for migrated settings, never duplicate a subsystem in legacy configuration, and let Talos select API-server advertise addresses. Built-in IPv6 KubeSpan advertises only IPv6 peers.

Load `terraform-talos-modules` → `references/networking.md` before network changes. Run `terraform fmt -check` here and parse changed YAML under `patches/`.
