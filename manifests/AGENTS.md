# Cluster manifests

## Purpose

Maintain Kustomize overlays and Helm values for required and optional Kubernetes components deployed after Talos bootstrap.

## Ownership

- Each component directory owns its `kustomization.yaml`, local patches/resources, chart version, and Helm values.
- `namespaces.yaml` owns shared namespace creation; `README.md` owns the component catalog and deployment guidance.
- Checked-in `charts/` content is fetched Helm material; change component intent in the owning Kustomization unless intentionally vendoring a chart.

## Local Contracts

- Keep IPv4 and IPv6 Cilium configurations behaviorally aligned except for address-family-specific values.
- Cilium must remain compatible with kube-proxy-disabled Talos patches and the selected DNS/KubeSpan behavior.
- Rendered output belongs in `.build/manifests/` and must not become the source of truth.
- Keep chart and remote resource versions explicit and reproducible.

## Work Guidance

- Update the component table when adding, removing, or materially changing a component.
- Review security contexts, CRDs, API versions, and upgrade notes when changing chart versions.

## Verification

- Render an affected component with `kustomize build --enable-helm manifests/<component>`.
- Run `just build` for cross-component or root build changes.

## Child DOX Index

