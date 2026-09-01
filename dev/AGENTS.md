# Development deployment

Exercise public module interfaces in parallel IPv4/IPv6 multi-cloud clusters; do not hide module defaults. State, plans, Talos configs, and kubeconfigs are sensitive local artifacts.

`1-talos-ipv6-direct.tf` owns fail-closed IPv6-only KubeSpan endpoints, aggregate `fc00:1::/96` routing, and pod-to-node-pool table-`180` rules in `talos-cluster.patches.common`. Keep KubeSpan/route MTU 1420 and Cilium MTU 1400; use Talos 1.14 document resources and built-in node CIDR allocation.

Never run `just apply` or `just destroy` for validation. Run `terraform fmt -check`; validate only after initialization. When a live direct-routing cluster is intentionally available, `just verify-ipv6-direct` is the self-cleaning release/teardown check.
