# manifests
Kustomize + Helm chart configurations for cluster components. Run `just build` from the repo root to render them into `.build/manifests/`.

## components

| name | description | required |
|---|---|---|
| [argocd](argocd) | GitOps controller | no |
| [cert-manager](cert-manager) | certificate management | no |
| [cilium-ipv6](cilium-ipv6) | CNI for IPv6 clusters - tunnel mode (netkit), bandwidth manager, Gateway API | yes |
| [cilium-ipv6-direct](cilium-ipv6-direct) | CNI for IPv6 clusters - native routing over KubeSpan WireGuard, no VXLAN | no |
| [cilium-ipv4](cilium-ipv4) | CNI for IPv4 clusters - tunnel mode (netkit), bandwidth manager, Gateway API | yes |
| [coredns-ipv6](coredns-ipv6) | CoreDNS with `hostNetwork: true` for IPv6 clusters (legacy workaround, no longer required) | no |
| [coredns-ipv4](coredns-ipv4) | CoreDNS with `hostNetwork: true` for IPv4 clusters (legacy workaround, no longer required) | no |
| [coroot](coroot) | observability | no |
| [external-secrets](external-secrets) | sync secrets from external stores | no |
| [gcp-wif-webhook](gcp-wif-webhook) | GCP Workload Identity Federation webhook | no |
| [hcloud-ccm](hcloud-ccm) | Hetzner Cloud Controller Manager | no |
| [hcloud-csi](hcloud-csi) | Hetzner CSI driver | no |
| [iperf](iperf) | network benchmarking | no |
| [scaleway-csi](scaleway-csi) | Scaleway CSI driver | no |
| [talos-ccm](talos-ccm) | Talos Cloud Controller Manager - node IPAM and cloud metadata | no |

[namespaces.yaml](namespaces.yaml) creates the namespaces shared across components.

> **Note:** The Cilium manifests use eBPF host routing (`bpf.hostLegacyRouting: false`) so pod traffic bypasses the host netfilter/iptables stack. Talos hostDNS remains enabled, but forwarding Kubernetes DNS to hostDNS is explicitly disabled in the cluster patches because that feature is incompatible with Cilium eBPF host routing. The `coredns-ipv4` / `coredns-ipv6` manifests (`hostNetwork: true` workaround) are kept for reference but are no longer required.

`cilium-ipv6-direct` is the encrypted native-routing alternative. It requires
KubeSpan `advertiseKubernetesNetworks: true` and `allowDownPeerBypass: false` on
every node, with `filters.endpoints: [::/0]` so provider IPv4/CGNAT addresses
remain available to host-network processes without becoming WireGuard peer
endpoints. It keeps eBPF host routing enabled, routes the predefined
`fc00:1::/96` Pod CIDR natively, and applies BPF IPv6 masquerading only to
off-cluster traffic. Cilium explicitly uses `kubespan` as its direct-routing
device and restricts NodePort addresses to `::/0`, while retaining `eth0` for
off-cluster masquerading. Its
1420-byte MTU assumes a 1500-byte physical underlay. Remote-node masquerading
is deliberately disabled: with IPv6 BPF masquerading it drops pod-to-node
traffic before Talos policy routing can select KubeSpan.

Cilium's eBPF host routing bypasses Talos' KubeSpan packet marking for traffic
from pods to remote node addresses. Configure destination-scoped Talos
`RoutingRuleConfig` documents that match the Pod CIDR as `src`, each node
public allocation as `dst`, and select KubeSpan table `180`. This carries both
direct pod-to-node connections and Services backed by node addresses, including
the Kubernetes API, through WireGuard. Do not add node public `/128` routes to
the main table: those routes can recursively capture WireGuard peer endpoints
and break node-to-node traffic, including etcd.

## usage

```shell
# render all manifests to .build/manifests/
> just build

# apply required components (use cilium-ipv4 for IPv4 clusters)
> KUBECONFIG=kube-config kubectl apply --server-side=true -f .build/manifests/cilium-ipv6.yaml
> KUBECONFIG=kube-config kubectl apply --server-side=true -f .build/manifests/namespaces.yaml
```
