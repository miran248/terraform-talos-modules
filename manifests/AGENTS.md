# Cluster manifests

Own Kustomize/Helm component intent, explicit versions, shared namespaces, and the component catalog. Fetched `charts/` and rendered `.build/manifests/` are generated; update README components, CRDs, API versions, and security guidance with material changes.

Keep IPv4/IPv6 VXLAN Cilium profiles aligned by family. `cilium-ipv6-direct` remains KubeSpan-encrypted native routing for `fc00:1::/96`: eBPF host routing, `kubespan` device, NodePort `::/0`, off-cluster BPF IPv6 masquerading, no remote-node masquerading, and no Cilium iptables/L7/Gateway API/Envoy while reconciliation is incompatible.

Keep direct-routing Cilium MTU 1400; KubeSpan and aggregate PodCIDR routes use 1420. Pod-to-node traffic uses source/destination Talos rules selecting table `180`; never add node public `/128` routes to the main table. Keep Argo CD chart NetworkPolicies disabled where policy is managed separately.

Load `terraform-talos-modules` → `references/networking.md` for rationale. Render one affected component with `kustomize build --enable-helm manifests/<component>`; run `just build` for cross-component changes.
