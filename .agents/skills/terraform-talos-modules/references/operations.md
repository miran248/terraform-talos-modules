# Operations contracts

## Repository and manifests

- Root-owned assets include documentation, release history, `justfile`, ignores, licensing, and `.github/workflows`.
- `manifests/` owns Kustomize/Helm component intent, explicit chart/resource versions, shared namespaces, and the component catalog.
- Fetched `charts/` and rendered `.build/manifests/` are generated material, not source.
- Update the component table for added, removed, or materially changed components; review CRDs, API versions, security contexts, and upgrade notes on chart changes.

## Development

- `dev/` exercises public module interfaces in parallel IPv4 and IPv6 multi-cloud compositions; do not hide module defaults there.
- `dev/1-talos-ipv6-direct.tf` owns fail-closed IPv6-only KubeSpan endpoints, aggregate PodCIDR routing, and pod-to-node-pool policy rules in `talos-cluster.patches.common`.
- Talos 1.14 migrated settings use document resources.
- Terraform state/plans, Talos configs, and kubeconfigs are sensitive local artifacts.
- `just apply` and `just destroy` affect real cloud infrastructure. Do not run them for validation.
- `just verify-ipv6-direct` is a live, self-cleaning verification required before release or teardown when that cluster is available.

## Local cluster

- `local/` owns a disposable named Docker Talos cluster, separate common/control-plane patches, and `talosctl cluster` recipes.
- `.talos/`, `talos-config`, and `kube-config` are generated credentials/state.
- Use `talosctl patch machineconfig` for a running local cluster. Destructive recipes must target only the named local Docker cluster.

## Image builds

- `packer/` owns Hetzner/Scaleway templates, conversion/upload flow, temporary build paths, and operator docs.
- Keep architecture, Talos version/tag, schematic, registry names, and `scaleway-image` expectations aligned.
- Cloud/registry tokens, image payloads, and build output must not be committed.
- Build and publication recipes are billable external side effects; never run them as routine verification.

## Cluster commands

- Use `KUBECONFIG=kube-config kubectl ...` for repository-cluster Kubernetes commands.
- Use `TALOSCONFIG=talos-config talosctl ...` for repository-cluster Talos commands.
- For suffixed development configs, set the corresponding explicit file; never rely on process defaults.
