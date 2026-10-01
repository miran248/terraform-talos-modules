# Terraform modules

Modules own provider constraints, typed variables, resources/data sources, outputs, and READMEs. Their public interfaces and shared pool/node shapes are compatibility-sensitive; preserve secret and client-configuration sensitivity.

Keep `talos-cluster` provider-neutral. Cloud pools emit stable keys, address-family mode, and `removed` semantics; cloud apply modules return normalized nodes to `talos-apply`, which preserves control-plane-before-worker ordering.

Update callers, examples, documentation, validation, and release references with interface changes. Before changing modules, read [module contracts](../docs/maintenance/modules.md); select safe checks from [the verification matrix](../docs/maintenance/verification.md).

## Modules

- [hcloud-pool/AGENTS.md](hcloud-pool/AGENTS.md) and [hcloud-apply/AGENTS.md](hcloud-apply/AGENTS.md)
- [scaleway-pool/AGENTS.md](scaleway-pool/AGENTS.md), [scaleway-apply/AGENTS.md](scaleway-apply/AGENTS.md), and [scaleway-image/AGENTS.md](scaleway-image/AGENTS.md)
- [talos-cluster/AGENTS.md](talos-cluster/AGENTS.md) and [talos-apply/AGENTS.md](talos-apply/AGENTS.md)
- [gcp-wif/AGENTS.md](gcp-wif/AGENTS.md) and [gcp-wif-apply/AGENTS.md](gcp-wif-apply/AGENTS.md)
