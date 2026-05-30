# manifests
Kustomize + Helm chart configurations for cluster components. Run `just build` from the repo root to render them into `.build/manifests/`.

## components

| name | description | required |
|---|---|---|
| [cilium](cilium) | CNI - tunnel mode (netkit), BigTCP, BBR, Gateway API | yes |
| [talos-ccm](talos-ccm) | Talos Cloud Controller Manager - node IPAM and cloud metadata | yes |
| [argocd](argocd) | GitOps controller | no |
| [cert-manager](cert-manager) | certificate management | no |
| [coroot](coroot) | observability | no |
| [external-secrets](external-secrets) | sync secrets from external stores | no |
| [gcp-wif-webhook](gcp-wif-webhook) | GCP Workload Identity Federation webhook | no |
| [hcloud-ccm](hcloud-ccm) | Hetzner Cloud Controller Manager | no |
| [hcloud-csi](hcloud-csi) | Hetzner CSI driver | no |
| [iperf](iperf) | network benchmarking | no |

[namespaces.yaml](namespaces.yaml) creates the namespaces shared across components.

## usage

```shell
# render all manifests to .build/manifests/
> just build

# apply required components
> KUBECONFIG=kube-config kubectl apply --server-side=true -f .build/manifests/cilium.yaml
> KUBECONFIG=kube-config kubectl apply --server-side=true -f .build/manifests/talos-ccm.yaml
> KUBECONFIG=kube-config kubectl apply --server-side=true -f .build/manifests/namespaces.yaml
```
