# manifests
Kustomize + Helm chart configurations for cluster components. Run `just build` from the repo root to render them into `.build/manifests/`.

## components

| name | description | required |
|---|---|---|
| [argocd](argocd) | GitOps controller | no |
| [cert-manager](cert-manager) | certificate management | no |
| [cilium-ipv6](cilium-ipv6) | CNI for IPv6 clusters - tunnel mode (netkit), BigTCP, BBR, Gateway API | yes |
| [cilium-ipv4](cilium-ipv4) | CNI for IPv4 clusters - tunnel mode (netkit), BigTCP, BBR, Gateway API | yes |
| [coroot](coroot) | observability | no |
| [external-secrets](external-secrets) | sync secrets from external stores | no |
| [gcp-wif-webhook](gcp-wif-webhook) | GCP Workload Identity Federation webhook | no |
| [hcloud-ccm](hcloud-ccm) | Hetzner Cloud Controller Manager | no |
| [hcloud-csi](hcloud-csi) | Hetzner CSI driver | no |
| [iperf](iperf) | network benchmarking | no |
| [scaleway-csi](scaleway-csi) | Scaleway CSI driver | no |
| [talos-ccm](talos-ccm) | Talos Cloud Controller Manager - node IPAM and cloud metadata | no |

[namespaces.yaml](namespaces.yaml) creates the namespaces shared across components.

## usage

```shell
# render all manifests to .build/manifests/
> just build

# apply required components (use cilium-ipv4 for IPv4 clusters)
> KUBECONFIG=kube-config kubectl apply --server-side=true -f .build/manifests/cilium-ipv6.yaml
> KUBECONFIG=kube-config kubectl apply --server-side=true -f .build/manifests/namespaces.yaml
```
