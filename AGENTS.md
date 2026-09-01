# Repository agent context

## Contract

- Read this file and the nearest subtree `AGENTS.md` before editing.
- Keep portable, scope-specific constraints in `AGENTS.md`; load detailed procedures on demand from the project skill `terraform-talos-modules` at `.agents/skills/terraform-talos-modules/SKILL.md`.
- Preserve public Terraform interfaces, sensitive outputs, provider-neutral Talos composition, explicit release references, and reproducible Kubernetes manifests.
- Generated state, plans, credentials, rendered manifests, fetched charts, image payloads, and local editor metadata are not authored source.
- Do not apply/destroy infrastructure, mutate clusters, build/publish images, create tags, or push unless explicitly requested.

## Workflow

1. Identify changed scopes and read every `AGENTS.md` on their repository path.
2. Load the project skill reference for modules, networking, operations, release, or verification.
3. Implement with tests for behavior changes and run safe checks from `references/verification.md`.
4. Update the nearest context/reference when a durable contract changes; remove stale duplication.
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
