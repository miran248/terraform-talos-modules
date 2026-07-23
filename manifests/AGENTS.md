# Cluster manifests

## Purpose

Maintain Kustomize overlays and Helm values for required and optional Kubernetes components deployed after Talos bootstrap.

## Ownership

- Each component directory owns its `kustomization.yaml`, local patches/resources, chart version, and Helm values.
- `namespaces.yaml` owns shared namespace creation; `README.md` owns the component catalog and deployment guidance.
- Checked-in `charts/` content is fetched Helm material; change component intent in the owning Kustomization unless intentionally vendoring a chart.

## Local Contracts

- Keep IPv4 and IPv6 Cilium configurations behaviorally aligned except for address-family-specific values.
- Keep `cilium-ipv6` as the VXLAN variant and `cilium-ipv6-direct` as the KubeSpan-encrypted native-routing variant.
- Keep `cilium-ipv6-direct` native routing scoped to `fc00:1::/96` and enable BPF IPv6 masquerading for off-cluster traffic.
- Keep remote-node masquerading disabled in `cilium-ipv6-direct`; with IPv6 BPF masquerading it drops pod-to-node traffic as an invalid source before Talos policy routing can select KubeSpan.
- Keep `cilium-ipv6-direct` on eBPF host routing and explicitly select `kubespan` as Cilium's direct-routing device.
- Keep `cilium-ipv6-direct` at MTU 1400 while KubeSpan and the aggregate PodCIDR route use 1420, the inner-packet ceiling after IPv6 WireGuard overhead on a 1500-byte underlay. The lower Cilium MTU is independent headroom for the netkit/BPF path, where testing observed 1410-byte packets pass and 1411-byte packets drop as `FIB lookup failed`.
- Restrict `cilium-ipv6-direct` NodePort addresses to `::/0`; provider IPv4/CGNAT addresses may remain available to host-network processes but must not enter the IPv6-only service datapath.
- Keep Cilium iptables rule installation, L7 proxying, Gateway API, and Envoy disabled in `cilium-ipv6-direct` while Cilium's proxy-rule reconciliation fails on this Talos build even with L7 proxying disabled.
- Require destination-scoped Talos policy-routing rules from the Pod CIDR to every node public allocation through KubeSpan table `180` when pods must reach remote node addresses. Never add node public `/128` routes to the main table, because they recursively capture WireGuard peer endpoints.
- Cilium must remain compatible with kube-proxy-disabled Talos patches and the selected DNS/KubeSpan behavior.
- Keep Argo CD chart-managed NetworkPolicies disabled where cluster networking policy is managed separately.
- Rendered output belongs in `.build/manifests/` and must not become the source of truth.
- Keep chart and remote resource versions explicit and reproducible.

## Work Guidance

- Update the component table when adding, removing, or materially changing a component.
- Review security contexts, CRDs, API versions, and upgrade notes when changing chart versions.

## Verification

- Render an affected component with `kustomize build --enable-helm manifests/<component>`.
- Run `just build` for cross-component or root build changes.

## Child DOX Index
