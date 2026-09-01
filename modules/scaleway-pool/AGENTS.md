# Scaleway pool

Allocate routed IPs and placement metadata without creating instances. Emit the normalized `pools` shape consumed by `talos-cluster` and `scaleway-apply`.

Keep `mode` strictly `ipv4` or `ipv6`; allocated addresses must match. Preserve stable node keys, patch aggregation, and `removed` semantics. Verify with `terraform fmt -check` in this directory.
