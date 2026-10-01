# Talos and Kubernetes networking contracts

## Address families and Talos

- Built-in Talos patches are complete per-family sets; never combine IPv4 and IPv6 pools.
- The built-in IPv6 KubeSpan endpoint filter advertises only IPv6 peers. Provider IPv4/CGNAT addresses remain host-accessible but cannot become WireGuard endpoints.
- Keep Kubernetes DNS forwarding to Talos hostDNS disabled with Cilium eBPF host routing.
- Review CNI, DNS, KubeSpan, API endpoints, node CIDR allocation, routing, and MTU as one system.

## Cilium profiles

- Keep IPv4 and IPv6 VXLAN profiles behaviorally aligned except for family-specific values.
- `cilium-ipv6-direct` is the encrypted native-routing profile over KubeSpan, scoped to Pod CIDR `fc00:1::/96` with BPF IPv6 masquerading only for off-cluster traffic.
- Keep eBPF host routing enabled and select `kubespan` as the direct-routing device.
- Restrict NodePort addresses to `::/0`; provider IPv4/CGNAT addresses must not enter the IPv6-only service datapath.
- Keep remote-node masquerading disabled. With IPv6 BPF masquerading it drops pod-to-node traffic as an invalid source before Talos policy routing.
- Keep Cilium iptables rule installation, L7 proxying, Gateway API, and Envoy disabled while proxy-rule reconciliation fails on this Talos build.
- Keep Argo CD chart-managed NetworkPolicies disabled where networking policy is managed separately.

## Routing and MTU

- KubeSpan and the aggregate PodCIDR route use MTU 1420, the IPv6 WireGuard inner-packet ceiling on a 1500-byte underlay.
- `cilium-ipv6-direct` uses MTU 1400 for netkit/BPF headroom; live testing passed 1410-byte packets and dropped 1411-byte packets as `FIB lookup failed`.
- Pod-to-node traffic requires destination-scoped Talos `RoutingRuleConfig` documents: source `fc00:1::/96`, destination each node public allocation, table `180`.
- Never add node public `/128` routes to the main table; they can recursively capture WireGuard peer endpoints.
- Use built-in Kubernetes node CIDR allocation for direct-routing development, examples, and the local cluster unless a composition explicitly tests the cloud controller.
