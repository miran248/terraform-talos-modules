# Repository agent context

## Contract

- Read this file and the nearest subtree `AGENTS.md` before editing.
- Keep mandatory, scope-specific constraints and documentation pointers in `AGENTS.md`; keep detailed procedures in `docs/maintenance/`.
- Preserve public Terraform interfaces, sensitive outputs, provider-neutral Talos composition, explicit release references, and reproducible Kubernetes manifests.
- Generated state, plans, credentials, rendered manifests, fetched charts, image payloads, and local editor metadata are not authored source.
- Do not apply/destroy infrastructure, mutate clusters, build/publish images, create tags, or push unless explicitly requested.

## Workflow

1. Identify changed scopes and read every `AGENTS.md` on their repository path.
2. Read the maintenance guides relevant to the changed scopes below.
3. Implement with tests for behavior changes and run safe checks from [the verification matrix](docs/maintenance/verification.md); report unavailable checks.
4. Update the nearest `AGENTS.md` and affected maintenance guides when a durable contract changes; remove stale duplication.
5. Use Conventional Commits and leave a clean worktree.

For repository-cluster commands, set `KUBECONFIG=kube-config` for `kubectl` and `TALOSCONFIG=talos-config` for `talosctl`; never rely on default contexts.

## Domains

- [modules/AGENTS.md](modules/AGENTS.md) — reusable Terraform modules and public interfaces.
- [manifests/AGENTS.md](manifests/AGENTS.md) — Kustomize and Helm component intent.
- [dev/AGENTS.md](dev/AGENTS.md) — live dual-stack development compositions.
- [examples/AGENTS.md](examples/AGENTS.md) — copyable Terraform compositions.
- [local/AGENTS.md](local/AGENTS.md) — disposable local Talos workflow.
- [packer/AGENTS.md](packer/AGENTS.md) — cloud image registration/build workflows.

Release Please owns version PRs, changelog updates, tags, and releases. Repository module source references require `x-release-please-version` annotations and matching generic `extra-file` entries.

## Maintenance guides

- Before changing module interfaces or caller compositions, read [module contracts](docs/maintenance/modules.md).
- Before changing Talos, Cilium, KubeSpan, DNS, routing, or MTU, read [networking contracts](docs/maintenance/networking.md).
- Before changing development/local workflows, manifests, or image recipes, read [operations contracts](docs/maintenance/operations.md).
- Before rebasing the Talos fork, addressing upstream review, or rebuilding custom images, read [the Talos fork guide](docs/maintenance/talos-fork.md).
- Before changing release automation or version references, read [release contracts](docs/maintenance/release.md).

## Agent documentation

### Issue tracker

Track issues and specs in GitHub Issues. See `docs/agents/issue-tracker.md`.

### Triage labels

Use the five default triage labels. See `docs/agents/triage-labels.md`.

### Domain docs

Use a single-context glossary and ADR layout. See `docs/agents/domain.md`.
