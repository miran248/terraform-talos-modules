# Terraform modules

Modules own provider constraints, typed variables, resources/data sources, outputs, and READMEs. Their public interfaces and shared pool/node shapes are compatibility-sensitive; preserve secret and client-configuration sensitivity.

Keep `talos-cluster` provider-neutral. Cloud pools emit stable keys, address-family mode, and `removed` semantics; cloud apply modules return normalized nodes to `talos-apply`, which preserves control-plane-before-worker ordering.

Update callers, examples, documentation, validation, and release references with interface changes. Load `terraform-talos-modules` → `references/modules.md` for the complete module matrix and `references/verification.md` for safe checks.

## Modules

- [hcloud-pool/AGENTS.md](hcloud-pool/AGENTS.md) and [hcloud-apply/AGENTS.md](hcloud-apply/AGENTS.md)
- [scaleway-pool/AGENTS.md](scaleway-pool/AGENTS.md), [scaleway-apply/AGENTS.md](scaleway-apply/AGENTS.md), and [scaleway-image/AGENTS.md](scaleway-image/AGENTS.md)
- [talos-cluster/AGENTS.md](talos-cluster/AGENTS.md) and [talos-apply/AGENTS.md](talos-apply/AGENTS.md)
- [gcp-wif/AGENTS.md](gcp-wif/AGENTS.md) and [gcp-wif-apply/AGENTS.md](gcp-wif-apply/AGENTS.md)
