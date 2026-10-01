---
name: terraform-talos-modules
description: Maintain this repo's Terraform, Talos, and Kubernetes.
version: 1.0.0
author: Miran (miran248)
license: MIT
platforms: [linux, macos, windows]
---

# Terraform Talos Modules

Use this project skill for repository-specific implementation, maintenance, release, and verification work. It complements the nearest `AGENTS.md`; it does not replace portable subtree context.

## When to Use

- Editing a Terraform module or a caller composition.
- Changing Talos machine configuration or Kubernetes manifests.
- Building cloud images or operating development/local clusters.
- Updating release references or preparing verification.

Do not use it as generic Terraform, Kubernetes, or Talos guidance outside this repository.

## References

Load only the material relevant to the change:

- `references/modules.md` — module interfaces, ownership, and compatibility.
- `references/networking.md` — Talos, Cilium, KubeSpan, DNS, routing, and MTU contracts.
- `references/operations.md` — development, local-cluster, manifest, and image workflows.
- `references/release.md` — Release Please and version-reference contracts.
- `references/verification.md` — safe checks by changed area.

## Procedure

1. Read the root and nearest subtree `AGENTS.md`; identify the owning domain.
2. Load the smallest applicable reference set above.
3. Preserve public interfaces, sensitive outputs, ordering, and family-specific networking contracts.
4. Avoid live infrastructure, cluster mutation, image publication, and other external side effects unless explicitly requested.
5. Run the checks selected from `references/verification.md` and report unavailable checks.
6. Re-check the nearest `AGENTS.md` and affected references for contract drift.

## Pitfalls

- Generated Terraform state, plans, kubeconfigs, Talos configs, rendered manifests, charts, and image payloads are not source.
- A formatting check does not prove provider initialization, rendered YAML validity, or live networking behavior.
- IPv6 direct routing has coupled Talos, KubeSpan, Cilium, DNS, policy-routing, and MTU requirements; load `references/networking.md` before changing any part.
