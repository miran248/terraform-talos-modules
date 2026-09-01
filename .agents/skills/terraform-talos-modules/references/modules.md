# Module contracts

## Shared interface

- `modules/*` own provider constraints, typed variables, resources/data sources, outputs, and README documentation.
- Callers compose pool → `talos-cluster`/cloud apply → `talos-apply`; optional GCP WIF follows cluster bootstrap.
- Renamed or removed variables, output fields, resources, and changed defaults are compatibility-sensitive.
- Preserve sensitive markings for machine secrets, credentials, Talos client configuration, and Kubernetes credentials.
- Keep module READMEs, examples, release references, input validation, and shared object shapes synchronized.

## Pools and cloud apply

- `hcloud-pool` allocates primary IPs and placement metadata; `scaleway-pool` allocates routed IPs and placement metadata. Both emit stable node keys, `removed` semantics, a single `ipv4` or `ipv6` family, and the normalized `pools` shape consumed by `talos-cluster`.
- `hcloud-apply` creates servers, SSH material, and firewalls. `scaleway-apply` creates instances, ephemeral volumes, and security groups. Both match stable pool keys, omit removed nodes, preserve address-family rules, and return the shape expected by `talos-apply.applies`.
- Scaleway rules without `ip_range` are IPv4-only; explicitly select the pool family for IPv6-wide rules.
- `scaleway-image` registers an existing object-storage qcow2 as zone-scoped snapshot/image resources; building and upload remain under `packer/`.

## Talos modules

- `talos-cluster` stays provider-neutral. It normalizes pools/nodes, chooses versions, aggregates built-in and caller patches, renders machine configuration, and exposes provider-neutral cloud-apply outputs.
- Reject mixed-family pools. Preserve patch precedence: built-in → cluster → pool → role → node.
- Use Talos document resources for migrated settings; never configure one subsystem in both document and legacy machine formats.
- Let Talos select API-server advertise addresses; wildcard values are only for bind addresses.
- `talos-apply` consumes normalized nodes without cloud branching and preserves control-plane-before-worker phases, drain behavior, installer-image upgrades, bootstrap, and kubeconfig sensitivity. Do not rely on custom Terraform CLI parallelism.

## Workload identity

- `gcp-wif` owns identity pool/provider, OIDC bucket access, signing key, service accounts, IAM bindings, and Talos issuer patches.
- Kubernetes subjects use `namespace:name`; keep mappings, provider conditions, IAM membership, issuer URLs, and exported identifiers aligned.
- `gcp-wif-apply` runs after a reachable bootstrapped API exists, handles temporary TLS client material as sensitive, and publishes matching JWKS and OpenID configuration documents.
