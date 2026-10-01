# Development deployment

Exercise public module interfaces in parallel IPv4/IPv6 multi-cloud clusters; do not hide module defaults. State, plans, Talos configs, and kubeconfigs are sensitive local artifacts.

Committed development configuration always uses `dev1`. Later development iterations (`dev2`, `dev3`, etc.) are temporary local changes and must not enter commits. Before recreating clusters or restoring the baseline, follow [development iterations](../docs/maintenance/operations.md#development-iterations), including its post-test teardown: use a reviewed targeted destroy plan, or comment out active `1-talos-*.tf` declarations and apply, while preserving shared resources.

`1-talos-ipv6-direct.tf` owns fail-closed IPv6-only KubeSpan endpoints, aggregate `fc00:1::/96` routing, and pod-to-node-pool table-`180` rules in `talos-cluster.patches.common`. Keep KubeSpan/route MTU 1420 and Cilium MTU 1400; use Talos 1.14 document resources and built-in node CIDR allocation.

`1-talos-ipv4.tf` also owns pod-source/node-destination table-`180` rules for its netkit/BPF/VXLAN composition. This is a tested KubeSpan integration choice, not a general Cilium requirement. Follow [Cilium change validation](../docs/maintenance/networking.md#cilium-change-validation) for state isolation and the 15-minute failure-observation window.

Never run `just apply` or `just destroy` for validation. Run `terraform fmt -check`; validate only after initialization. When the corresponding live clusters are intentionally available, run the self-cleaning release/teardown checks: `just verify-ipv6-direct` and `just verify-ipv4`.

Before changing development compositions or workflows, read [module contracts](../docs/maintenance/modules.md) and [operations contracts](../docs/maintenance/operations.md); for network changes, also read [networking contracts](../docs/maintenance/networking.md).
