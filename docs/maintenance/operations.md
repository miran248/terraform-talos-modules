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
- `just verify-ipv6-direct` and `just verify-ipv4` are live, self-cleaning verifications required before release or teardown when their clusters are available.

### Dependency upgrade follow-up

The 2026-10-01 development test started with Cilium 1.19.6 and Kubernetes 1.36.1.
Cilium's [1.19 compatibility matrix](https://github.com/cilium/cilium/blob/v1.19.8/Documentation/network/kubernetes/compatibility.rst)
lists Kubernetes through 1.35; its [1.20 matrix](https://github.com/cilium/cilium/blob/v1.20.2/Documentation/network/kubernetes/compatibility.rst)
includes 1.36. Development now selects Cilium 1.20.2, Gateway API 1.6.1, and
Kubernetes 1.36.5. Upgrade existing Cilium installations through the latest
patch of the preceding minor (1.19.8 in this test), and install Gateway API
1.6.1 CRDs before Cilium 1.20. Both Cilium upgrades left the IPv4 pod-to-API
failure reproducible; the routing experiment and upstream guidance are documented in
[networking contracts](networking.md#ipv4-bpfkubespan-investigation). The newer versions
alone did not fix it. See [client compatibility](talos-fork.md#client-compatibility-during-development)
for the development Talos/provider limitation on in-place Kubernetes upgrades.

Review Cilium, Gateway API CRDs, Kubernetes, Talos, and Terraform providers as
a compatibility set, then test one upgrade at a time. Keep a failing baseline
and record the effective routing/masquerading settings and convergence time.
Run both networking/Gateway suites and a fresh development iteration before
accepting the new versions. Review the remaining Helm components separately
so unrelated updates do not obscure a networking regression.

### Development iterations

Use a fresh development iteration to test first boot and cluster bootstrap after changes that an update or repair cannot fully validate. `dev1` is the committed baseline; `dev2`, `dev3`, and later `devN` names identify temporary local iterations, not releases or installer versions. The commit constraint is owned by [dev/AGENTS.md](../../dev/AGENTS.md).

1. Inspect the selected Terraform workspace, current state, and worktree before choosing the next iteration. Record which iteration is live and preserve unrelated local work. A clean checkout alone does not establish which iteration is deployed.
2. Prepare temporary changes to cluster-specific names, node prefixes, and Terraform addresses. Keep the tested installer tag and instance types such as `DEV1-M` unchanged unless those are independently under test. Preserve shared image registration and GCP identity resources; inspect ownership of shared OIDC objects before renaming their publishing modules.
3. Review a saved Terraform plan. Confirm that the intended clusters receive fresh nodes and Talos secrets, and inspect every deletion and replacement. Renaming display names or moving state alone does not establish a fresh bootstrap. Decide explicitly whether the old iteration is retired first or overlaps with the new one; account for shared resources and concurrent cloud capacity. Apply or teardown requires authorization for those live actions.
4. Provision the new iteration, regenerate its client configs, install the Cilium profiles with Gateway API enabled, and run both address-family suites in [dev/README.md](../../dev/README.md). Verify stable node identities, three healthy etcd members per cluster, and all nodes Ready. Record the iteration and tested image version with the results; identify any manual repair separately from an uninterrupted first-boot pass.
5. After testing, prefer a targeted destroy when its reviewed plan removes exactly the intended iteration. Enumerate addresses from the current configuration and `terraform state list`: include the cluster-specific pool, cloud-apply, Talos-cluster, Talos-apply, and workload-identity publishing modules, plus the root load-balancer IPs, load balancers, backends, and frontends for both address families. Use the actual live iteration's addresses, not a hard-coded `dev1` list. Targeting accepts resource/module addresses, not filenames or shell-style wildcards. Prepare a saved plan with `terraform plan -destroy` and explicit `-target` arguments, review it, then execute it with `terraform apply` against that saved plan. This avoids temporary commenting; `terraform destroy -target=...` is also available, but does not consume a previously reviewed saved plan.
   - Inspect all planned actions, including any resources included through dependencies. Preserve shared image registration and GCP identity resources; targeting alone is not an isolation guarantee. Confirm which OIDC publications are owned by the retiring clusters. If the target set produces an unsafe or incomplete teardown, use the configuration-driven alternative below. See [Terraform resource targeting](https://developer.hashicorp.com/terraform/cli/commands/plan#resource-targeting) for its limitations.
   - Alternative: comment out all active declarations in `dev/1-talos-*.tf`, including cluster-specific outputs and workload-identity publishing modules. Leave inactive alternatives commented out and shared image/identity configuration enabled. Review and apply a normal saved plan that removes only the intended resources.
   - For either method, verify cluster removal in both Terraform state and the cloud provider. A workspace-wide `terraform destroy` (including `just destroy`) also removes shared resources and is not the iteration cleanup command.
6. Restore the committed `dev1` baseline after teardown, undoing temporary names and any teardown commenting while retaining durable fixes and documentation. Do not apply the restored baseline as a cleanup step: it declares clusters again and would recreate them. If teardown fails, retain the matching local iteration configuration and state details until cleanup is resolved; a source-file restore does not remove live resources.
7. Review the staged diff to ensure the development configuration uses `dev1`; temporary iteration names, teardown commenting, state, plans, credentials, and rendered manifests stay out of commits. Documentation may describe the `devN` convention. Commit durable changes separately from the local iteration.

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
