# manifests
Kustomize + Helm chart configurations for cluster components. Run `just build` from the repo root to render them into `.build/manifests/`.

## components

| name | description | required |
|---|---|---|
| [argocd](argocd) | GitOps controller | no |
| [cert-manager](cert-manager) | certificate management | no |
| [cilium-ipv6](cilium-ipv6) | CNI for IPv6 clusters - tunnel mode (netkit), BigTCP, BBR, Gateway API | yes |
| [cilium-ipv4](cilium-ipv4) | CNI for IPv4 clusters - tunnel mode (netkit), BigTCP, BBR, Gateway API | yes |
| [coredns-ipv6](coredns-ipv6) | CoreDNS with `hostNetwork: true` for IPv6 clusters | yes* |
| [coredns-ipv4](coredns-ipv4) | CoreDNS with `hostNetwork: true` for IPv4 clusters | yes* |
| [coroot](coroot) | observability | no |
| [external-secrets](external-secrets) | sync secrets from external stores | no |
| [gcp-wif-webhook](gcp-wif-webhook) | GCP Workload Identity Federation webhook | no |
| [hcloud-ccm](hcloud-ccm) | Hetzner Cloud Controller Manager | no |
| [hcloud-csi](hcloud-csi) | Hetzner CSI driver | no |
| [iperf](iperf) | network benchmarking | no |
| [scaleway-csi](scaleway-csi) | Scaleway CSI driver | no |
| [talos-ccm](talos-ccm) | Talos Cloud Controller Manager - node IPAM and cloud metadata | no |

[namespaces.yaml](namespaces.yaml) creates the namespaces shared across components.

> **\*Note:** Talos hostDNS and the Talos-managed CoreDNS are both disabled in the built-in cluster patches (`cluster.coreDNS.disabled: true`, `ResolverConfig hostDNS.enabled: false`). CoreDNS must be deployed via the `coredns-ipv4` / `coredns-ipv6` manifests instead. These run CoreDNS with `hostNetwork: true` as a workaround for a Cilium BPF masquerade bug that skips DNAT on the KubeSpan interface for established TCP flows, causing cross-cloud DNS resolution to fail. Both will be re-enabled once a proper upstream fix is available.

## usage

```shell
# render all manifests to .build/manifests/
> just build

# apply required components (use cilium-ipv4 / coredns-ipv4 for IPv4 clusters)
> KUBECONFIG=kube-config kubectl apply --server-side=true -f .build/manifests/cilium-ipv6.yaml
> KUBECONFIG=kube-config kubectl apply --server-side=true --force-conflicts -f .build/manifests/coredns-ipv6.yaml
> KUBECONFIG=kube-config kubectl apply --server-side=true -f .build/manifests/namespaces.yaml
```
