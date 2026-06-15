# Changelog

## Unreleased

### breaking changes
- [talos-apply](modules/talos-apply) replaces `talos_machine_configuration_apply` + `talos_machine_bootstrap` with `talos_machine` + `talos_cluster` — existing state requires resource recreation on first apply
- [hcloud-apply](modules/hcloud-apply) and [scaleway-apply](modules/scaleway-apply) output `nodes` instead of `ips` — update references from `module.x_apply.ips.v6[k]` to `module.x_apply.nodes[k].ip`
- [talos-apply](modules/talos-apply) `applies` variable now expects objects with a `nodes` map instead of `ips.v6`
- [hcloud-pool](modules/hcloud-pool) and [scaleway-pool](modules/scaleway-pool) pool output field `ip_64` renamed to `ip_cidr`; `ids.ips.v6` renamed to `ids.ips`
- Ports 80/443 removed from default firewall rules — pass via `rules` / `inbound_rules` if needed
- Removed private network and load balancer resources from hcloud modules

### features
- **Scaleway support** — new [scaleway-pool](modules/scaleway-pool), [scaleway-apply](modules/scaleway-apply), [scaleway-image](modules/scaleway-image) modules; instances boot with routed IPv6, no IPv4 required
- **IPv4 support** — `mode` variable on [hcloud-pool](modules/hcloud-pool) and [scaleway-pool](modules/scaleway-pool) (`"ipv6"` default, `"ipv4"` option); [talos-cluster](modules/talos-cluster) validates all pools share the same mode and selects matching built-in patches automatically; [cilium-ipv6](manifests/cilium-ipv6) and [cilium-ipv4](manifests/cilium-ipv4) manifests
- **Rolling OS upgrades** — [talos-apply](modules/talos-apply) uses `talos_machine` + `talos_cluster` from talos provider 0.12.x for proper lifecycle management and rolling upgrades
- **Custom installer image** — `installer_image` variable on [talos-apply](modules/talos-apply) for custom schematics or dev builds
- **Extensible firewall rules** — `rules` ([hcloud-apply](modules/hcloud-apply)) and `inbound_rules` ([scaleway-apply](modules/scaleway-apply)) for adding extra rules per pool; built-in rules now conditional (6443 and 50001 only on pools with control planes)

### changes
- Cilium switched from direct routing to tunnel mode (netkit datapath)
- All module resources consolidated into `main.tf` per module
- Upgraded talos provider to 0.12.x, hcloud, scaleway, and google providers upgraded

### manifests
- [cilium](manifests/cilium-ipv6) renamed to `cilium-ipv6`; `cilium-ipv4` added
- Added [cert-manager](manifests/cert-manager), [external-secrets](manifests/external-secrets), [scaleway-csi](manifests/scaleway-csi), [coroot](manifests/coroot) manifests
- Added [coredns-ipv4](manifests/coredns-ipv4) and [coredns-ipv6](manifests/coredns-ipv6) — CoreDNS with `hostNetwork: true` and explicit upstream nameservers (legacy workaround, kept for reference)
- [hcloud-csi](manifests/hcloud-csi) and [scaleway-csi](manifests/scaleway-csi) node DaemonSets scoped to their respective `provider` node label
- Cilium socketLB and BPF masquerade enabled; `bpf.hostLegacyRouting: true` fixes Cilium BPF masquerade skipping DNAT on KubeSpan for established TCP flows in cross-cloud clusters
- BigTCP disabled — requires pending kernel support in VXLAN tunnel mode
- BBR disabled — incompatible with `bpf.hostLegacyRouting: true`
- Cilium, ArgoCD, and other manifest dependencies updated

### breaking changes (continued)
- Firewall rules for ports 51820/4240/8472 removed from hcloud-apply and scaleway-apply — covered by intra-cluster dynamic rules

### docs
- READMEs added or rewritten for all modules
- New examples: [scaleway-lb.tf](examples/scaleway-lb.tf), [multi-cloud.tf](examples/multi-cloud.tf), [talos-ccm.tf](examples/talos-ccm.tf)
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
