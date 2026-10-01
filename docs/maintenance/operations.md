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

### Development iterations

Use a fresh development iteration to test first boot and cluster bootstrap after changes that an update or repair cannot fully validate. `dev1` is the committed baseline; `dev2`, `dev3`, and later `devN` names identify temporary local iterations, not releases or installer versions. The commit constraint is owned by [dev/AGENTS.md](../../dev/AGENTS.md).

1. Inspect the selected Terraform workspace, current state, and worktree before choosing the next iteration. Record which iteration is live and preserve unrelated local work. A clean checkout alone does not establish which iteration is deployed.
2. Prepare temporary changes to cluster-specific names, node prefixes, and Terraform addresses. Keep the tested installer tag and instance types such as `DEV1-M` unchanged unless those are independently under test. Preserve shared image registration and GCP identity resources; inspect ownership of shared OIDC objects before renaming their publishing modules.
3. Review a saved Terraform plan. Confirm that the intended clusters receive fresh nodes and Talos secrets, and inspect every deletion and replacement. Renaming display names or moving state alone does not establish a fresh bootstrap. Decide explicitly whether the old iteration is retired first or overlaps with the new one; account for shared resources and concurrent cloud capacity. Apply or teardown requires authorization for those live actions.
4. Provision the new iteration, regenerate its client configs, install the Cilium profiles with Gateway API enabled, and run the checks in [dev/README.md](../../dev/README.md). Verify stable node identities, three healthy etcd members per cluster, all nodes Ready, and the complete IPv6 direct-routing suite. Record the iteration and tested image version with the results; identify any manual repair separately from an uninterrupted first-boot pass.
5. Before restoring local files to `dev1`, decide what happens to the live iteration. If retiring it, use its matching configuration and a reviewed teardown plan that preserves shared resources. If keeping it running, retain a private, untracked patch or separate local checkout that reproduces its configuration, plus its workspace and iteration details. Restoring files changes neither live resources nor Terraform state: applying the restored `dev1` configuration to a workspace still managing `devN` can destroy and recreate clusters. Reconstruct the matching iteration configuration before further operations and review a new plan.
6. Restore only the temporary iteration edits, retaining fixes and documentation that should be committed. Review the staged diff to ensure the development configuration uses `dev1`; temporary iteration names, state, plans, credentials, and rendered manifests stay out of commits. Documentation may describe the `devN` convention. Commit durable changes separately from the local iteration.

## Local cluster

- `local/` owns a disposable named Docker Talos cluster, separate common/control-plane patches, and `talosctl cluster` recipes.
- `.talos/`, `talos-config`, and `kube-config` are generated credentials/state.
- Use `talosctl patch machineconfig` for a running local cluster. Destructive recipes must target only the named local Docker cluster.

## Image builds

- `packer/` owns Hetzner/Scaleway templates, conversion/upload flow, temporary build paths, and operator docs.
- Keep architecture, Talos version/tag, schematic, registry names, and `scaleway-image` expectations aligned.
- Cloud/registry tokens, image payloads, and build output must not be committed.
- Build and publication recipes are billable external side effects; never run them as routine verification.

For rebasing the Talos fork, addressing upstream review, or rebuilding custom images, read [talos-fork.md](talos-fork.md). It owns Talos-specific contribution checks, Scaleway quirks, and build recovery.

## Cluster commands

- Use `KUBECONFIG=kube-config kubectl ...` for repository-cluster Kubernetes commands.
- Use `TALOSCONFIG=talos-config talosctl ...` for repository-cluster Talos commands.
- For suffixed development configs, set the corresponding explicit file; never rely on process defaults.
