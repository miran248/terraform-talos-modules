# dev
Development clusters used for testing. The active composition deploys two Scaleway Paris clusters, one IPv6 and one IPv4, each with three control planes and one worker. The Hetzner pool is currently commented out.

## fresh development iterations

The committed configuration always uses `dev1`. For a fresh end-to-end deployment,
use a temporary local iteration such as `dev2` or `dev3`, following the
[development iteration procedure](../docs/maintenance/operations.md#development-iterations).
Commit durable fixes with the `dev1` baseline, never the temporary rename.
After testing, use a reviewed targeted destroy plan, or temporarily comment out
the active `1-talos-*.tf` declarations and apply, preserving shared resources. Restore the committed
`dev1` baseline only after cleanup; applying it again would recreate the clusters.

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
> KUBECONFIG=kube-config-ipv6 kubectl apply --server-side=true -f .build/manifests/cilium-ipv6-direct.yaml
> KUBECONFIG=kube-config-ipv6 kubectl apply --server-side=true -f manifests/namespaces.yaml
> KUBECONFIG=kube-config-ipv4 kubectl apply --server-side=true -f .build/manifests/cilium-ipv4.yaml
> KUBECONFIG=kube-config-ipv4 kubectl apply --server-side=true -f manifests/namespaces.yaml
```

On a fresh cluster, the first apply can report that `GatewayClass` is not yet
recognized while its CRD is being established. Wait for the CRD with
`KUBECONFIG=kube-config-ipv4 kubectl wait --for=condition=Established crd/gatewayclasses.gateway.networking.k8s.io --timeout=60s`,
then repeat that cluster's Cilium apply command. Use the corresponding IPv6
kubeconfig if the IPv6 installation reports the same error.

The IPv6 development composition enables the KubeSpan patches required by
native routing and advertises only IPv6 WireGuard endpoints, leaving any
provider IPv4/CGNAT addresses available only to the host. It also installs
source-and-destination policy rules that send
pod traffic for every node public allocation through KubeSpan table `180`.
KubeSpan and the aggregate PodCIDR route use MTU 1420, while Cilium
independently limits pod traffic to MTU 1400 for netkit/BPF headroom.
Use `.build/manifests/cilium-ipv6-direct.yaml` for this composition to test
encrypted direct pod and pod-to-node routing without VXLAN.

Gateway API is an acceptance requirement after dev provisioning and installation
of `manifests/cilium-ipv6-direct`; Terraform provisioning alone does not install
Cilium or make Gateway API available. The profile includes Gateway API CRDs.
Gateway API, Envoy, L7 proxying, and the required iptables rules are enabled.
The older proxy-reconciliation workaround has been removed. See the
[networking contract](../docs/maintenance/networking.md#cilium-profiles) for
the validated Talos/Cilium combination. The full suite checks cluster
networking as well as Gateway traffic; rerun it after deployment or changes.

Run the repeatable direct-routing smoke suite before destroying the cluster:

```shell
> cd dev
> just verify-ipv6-direct
```

The inline just recipe checks Cilium health from every node, KubeSpan peers and
policy rules, worker-pod access to DNS, every API backend, public IPv6 and
NAT64, plus a temporary Gateway API HTTP route. Temporary resources are removed
on exit.

## remove test clusters

Follow the [iteration cleanup procedure](../docs/maintenance/operations.md#development-iterations):
prefer a saved targeted destroy plan covering the live iteration's cluster modules
and load-balancer resources. Inspect the complete plan to preserve shared image
and identity resources. Temporarily commenting out the active `1-talos-*.tf`
declarations and applying a normal plan remains an alternative.
`just destroy` tears down the entire workspace and is not the iteration cleanup command.
