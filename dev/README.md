# dev
Development clusters used for testing. Deploys two clusters - one IPv6, one IPv4 - across Scaleway (Paris, control planes) and Hetzner Cloud (Nuremberg, workers).

## prerequisites
- [Terraform](https://developer.hashicorp.com/terraform)
- [just](https://github.com/casey/just)
- [talosctl](https://www.talos.dev/latest/introduction/getting-started/#talosctl)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [k9s](https://k9scli.io/) (optional)
- Scaleway and Hetzner Cloud credentials configured

## deploy

```shell
> cd dev
> just
```

This runs `terraform init`, `terraform apply`, and writes configs to the repo root:
- `talos-config-ipv6` / `kube-config-ipv6`
- `talos-config-ipv4` / `kube-config-ipv4`

## verify nodes

```shell
> TALOSCONFIG=talos-config-ipv6 talosctl -n c1 dashboard
> TALOSCONFIG=talos-config-ipv4 talosctl -n c1 dashboard
```

## apply manifests

Run `just` from the repo root to render manifests, then apply CNI and namespaces:

```shell
> just
> KUBECONFIG=kube-config-ipv6 kubectl apply --server-side=true -f .build/manifests/cilium-ipv6.yaml
> KUBECONFIG=kube-config-ipv6 kubectl apply --server-side=true -f .build/manifests/namespaces.yaml
> KUBECONFIG=kube-config-ipv4 kubectl apply --server-side=true -f .build/manifests/cilium-ipv4.yaml
> KUBECONFIG=kube-config-ipv4 kubectl apply --server-side=true -f .build/manifests/namespaces.yaml
```

The IPv6 development composition enables the KubeSpan patches required by
native routing. Apply `.build/manifests/cilium-ipv6-direct.yaml` instead of
`cilium-ipv6.yaml` to test encrypted direct pod routing without VXLAN.

## destroy

```shell
> just destroy
```
