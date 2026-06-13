# Changelog

## Unreleased

### breaking changes
- [hcloud-apply](modules/hcloud-apply) and [scaleway-apply](modules/scaleway-apply) now output `nodes` instead of `ips` — each node object is the pool node enriched with an `ip` field. Update references from `module.x_apply.ips.v6[k]` to `module.x_apply.nodes[k].ip`.
- [talos-apply](modules/talos-apply) `applies` variable now expects objects with a `nodes` map instead of `ips.v6`.
- [talos-apply](modules/talos-apply) replaces `talos_machine_configuration_apply` + `talos_machine_bootstrap` with `talos_machine` + `talos_cluster` — existing state will require resource recreation on first apply.

### features
- **IPv6-only Scaleway support** — IPv4 no longer required
- **Scaleway load balancer examples** — new [scaleway-lb.tf](examples/scaleway-lb.tf) and [multi-cloud.tf](examples/multi-cloud.tf) examples
- **Rolling upgrades via `talos_machine`** — [talos-apply](modules/talos-apply) now uses `talos_machine` + `talos_cluster` resources for proper lifecycle management and rolling OS upgrades
- **`installer_image` variable** on [talos-apply](modules/talos-apply) — override the Talos installer image for custom schematics or dev builds
- **Conditional firewall rules** — ports 6443 (apiserver) and 50001 (trustd) only opened on pools containing control planes; 50000 (apid) opened on all nodes
- **Extensible firewall rules** — `rules` ([hcloud-apply](modules/hcloud-apply)) and `inbound_rules` ([scaleway-apply](modules/scaleway-apply)) variables for adding extra rules per deployment
- **Scaleway security group hardened** — `inbound_default_policy = "drop"` with explicit `ip_range = "::/0"` on all public rules (required for IPv6-only instances — rules without `ip_range` are treated as IPv4-only by Scaleway)

### changes
- All module resource files consolidated into `main.tf` per module
- [scaleway-pool](modules/scaleway-pool) drops IPv4 IPs — instances boot IPv6-only
- [scaleway-pool](modules/scaleway-pool) removes `network.interfaces.eth0.dhcp` patch — network configured statically by Talos platform code
- Port 80/443 removed from default firewall rules — pass via `rules`/`inbound_rules` if needed
- Port 10256 (kube-proxy healthz) removed — not applicable when using Cilium as kube-proxy replacement

### docs
- READMEs updated across all modules — complex types in subsections, module output inputs link to source module
- New examples: [scaleway-lb.tf](examples/scaleway-lb.tf), [multi-cloud.tf](examples/multi-cloud.tf)
- CHANGELOG switched to manual maintenance

## [v3.2.3](https://github.com/miran248/terraform-talos-modules/compare/v3.2.2...v3.2.3) — 2025-12-04

- upgrade hcloud provider to 1.60.1

## [v3.2.2](https://github.com/miran248/terraform-talos-modules/compare/v3.2.1...v3.2.2) — 2025-08-14

- ensure hcloud-csi runs on the correct nodes
- use newer gateway API

## [v3.2.1](https://github.com/miran248/terraform-talos-modules/compare/v3.2.0...v3.2.1) — 2025-08-14

- try latest Talos and update manifests

## [v3.2.0](https://github.com/miran248/terraform-talos-modules/compare/v3.1.0...v3.2.0) — 2025-04-02

- update dependencies
- enable endpoint routing on Cilium

## [v3.1.0](https://github.com/miran248/terraform-talos-modules/compare/v3.0.0...v3.1.0) — 2024-12-10

- enable netkit datapath on Cilium

## [v3.0.0](https://github.com/miran248/terraform-talos-modules/compare/v2.1.0...v3.0.0) — 2024-12-06

- add optional private networks and load balancers
- enable KubeSpan
- change pod CIDR masks

## [v2.1.0](https://github.com/miran248/terraform-talos-modules/compare/v2.0.0...v2.1.0) — 2024-10-25

- add [gcp-wif](modules/gcp-wif) module

## [v2.0.0](https://github.com/miran248/terraform-talos-modules/compare/v1.3.0...v2.0.0) — 2024-10-23

- simplify setup
- remove support for IPv4 and private networks

## [v1.3.0](https://github.com/miran248/terraform-talos-modules/compare/v1.2.0...v1.3.0) — 2024-10-10

- ensure pods and services use IPv6 CIDRs in IPv6 cluster

## [v1.2.0](https://github.com/miran248/terraform-talos-modules/compare/v1.1.0...v1.2.0) — 2024-09-27

- disable firewalls

## [v1.1.0](https://github.com/miran248/terraform-talos-modules/compare/v1.0.0...v1.1.0) — 2024-09-27

- upgrade Talos

## [v1.0.0](https://github.com/miran248/terraform-talos-modules/compare/v0.1.0...v1.0.0) — 2024-09-20

- IPv6 + IPv4 dual-stack
- [talos-ccm](modules/talos-ccm), hcloud-csi

## [v0.1.0](https://github.com/miran248/terraform-talos-modules/releases/tag/v0.1.0) — 2024-08-28

- initial release: private network + routing
