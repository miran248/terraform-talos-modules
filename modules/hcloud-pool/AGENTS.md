# Hetzner Cloud pool

Allocate one primary IP per Talos node plus placement metadata without creating servers. Emit the normalized `pools` shape consumed by `talos-cluster` and `hcloud-apply`.

Keep `mode` strictly `ipv4` or `ipv6`; emitted addresses/CIDRs must match. Preserve stable node keys, patch aggregation, and `removed` semantics. Verify with `terraform fmt -check` in this directory.
