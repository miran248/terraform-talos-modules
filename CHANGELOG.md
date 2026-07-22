# Changelog

## [v4.2.2](https://github.com/miran248/terraform-talos-modules/compare/v4.2.1...v4.2.2) — 2026-07-22

### networking

- Disabled Cilium L7 proxying, Gateway API, and Envoy in the IPv6 direct-routing profile to avoid proxy-rule reconciliation failures on Talos kernels without legacy IPv4/IPv6 iptables compatibility
- Disabled Argo CD chart-managed NetworkPolicies so repository-server traffic is not constrained by policies that are incompatible with the current cluster networking

### compatibility

- Existing tunneled `cilium-ipv4` and `cilium-ipv6` profiles are unchanged

### release tooling

- Verify annotated release tags against the GitHub tag object instead of the checkout's dereferenced commit
- Updated every repository-owned example and module README self-reference from `v4.2.1` to `v4.2.2`

## [v4.2.1](https://github.com/miran248/terraform-talos-modules/compare/v4.2.0...v4.2.1) — 2026-07-19

### networking

- Added destination-scoped Talos `RoutingRuleConfig` patches to the IPv6 direct-routing development composition and example; pod traffic from `fc00:1::/96` to each node public allocation now selects KubeSpan table `180`
- Verified that worker pods can reach the Kubernetes API Service and control-plane public addresses through KubeSpan WireGuard while unrelated public IPv6 traffic continues through the normal underlay
- Kept Cilium remote-node masquerading disabled because IPv6 BPF masquerading dropped pod-to-node traffic as `Invalid source ip` before Talos policy routing
- Preserved the aggregate `fc00:1::/96` KubeSpan route for pod-to-pod traffic and retained the warning against main-table node `/128` routes, which can recursively capture WireGuard endpoints

### Talos configuration

- Removed wildcard kube-apiserver `advertise-address` values from the built-in IPv4, built-in IPv6, and local control-plane patches; Talos now selects a concrete address so Kubernetes publishes usable API endpoints
- Removed redundant local KubeSpan endpoint filters and retained fail-closed KubeSpan behavior

### examples and documentation

- Updated the encrypted direct-routing example with per-pool policy rules for pod-to-node traffic
- Added a self-cleaning inline development just recipe for all-node Cilium/KubeSpan health, worker API/DNS/NAT64 connectivity, and Gateway API traffic
- Documented the verified routing split, Kubernetes API/CoreDNS behavior, KubeSpan table selection, and advertise-address requirement across repository guidance

### compatibility

- No public module inputs or outputs changed
- Existing tunneled `cilium-ipv4` and `cilium-ipv6` profiles are unchanged

## [v4.2.0](https://github.com/miran248/terraform-talos-modules/compare/v4.1.0...v4.2.0) — 2026-07-19

### networking

- Added the optional [`cilium-ipv6-direct`](manifests/cilium-ipv6-direct) profile for encrypted IPv6 native routing over KubeSpan WireGuard without VXLAN or an external cloud controller
- The direct-routing profile uses Kubernetes node IPAM to allocate per-node `/112` PodCIDRs from `fc00:1::/96`, advertises them through KubeSpan, and installs an MTU-1420 main-table route for the aggregate Pod CIDR
- Kept the netkit datapath and eBPF host routing, explicitly selected `kubespan` as Cilium's direct-routing device, and enabled BPF IPv6 masquerading only for traffic outside `fc00:1::/96`
- Retained Gateway API, L7 proxy, Envoy, kube-proxy replacement, NodePort, hostPort, bandwidth manager, and BBR support in the direct-routing profile
- Documented that pods must use Services instead of remote node public IPs: that path bypasses Talos' KubeSpan marking, while routing node public `/128`s through `kubespan` can recursively capture WireGuard endpoints and break node traffic such as etcd

### Talos configuration

- Migrated resolver/hostDNS, KubeSpan, time sync, controller manager, and scheduler settings to Talos' document-based `ResolverConfig`, `KubeSpanConfig`, `TimeSyncConfig`, `KubeControllerManagerConfig`, and `KubeSchedulerConfig` formats
- Kept remaining machine and cluster settings in the legacy `v1alpha1` document where required for compatibility with Terraform Talos provider `0.12.0-alpha.5`
- Preserved built-in IPv4 and IPv6 node CIDR allocation and made the predefined IPv6 `fc00:1::/96` Pod subnet usable without Talos CCM
- Updated the local Talos patches and the Talos CCM example to the same supported document formats

### manifests

- Updated Argo CD to `10.1.4`, cert-manager to `1.21.0`, Coroot Operator to `0.9.7`, External Secrets to `2.7.0`, Hetzner Cloud Controller Manager to `1.34.0`, Hetzner CSI to `2.22.0`, and Talos Cloud Controller Manager to `0.5.5`
- Added `cilium-ipv6-direct` to the root manifest build

### providers and development

- Updated the development Talos provider from `0.12.0-alpha.4` to `0.12.0-alpha.5`, Google provider from `7.36.0` to `7.40.0`, Hetzner Cloud provider from `1.65.0` to `1.66.1`, and Scaleway provider from `2.76.0` to `2.79.0`
- Added a dedicated Scaleway IPv6 direct-routing development cluster using a static Pod CIDR, fail-closed KubeSpan, NAT64 resolvers, and no Talos CCM
- Clarified that HCP Terraform may configure nodes within a phase concurrently and does not accept a custom `-parallelism` CLI argument

### examples and documentation

- Added [`talos-direct-routing.tf`](examples/talos-direct-routing.tf) with the required fail-closed KubeSpan and aggregate PodCIDR route patches
- Removed redundant `cluster.network.cni.name: none` overrides from examples because the Talos cluster module already supplies them
- Expanded Cilium documentation with routing, masquerading, MTU, CoreDNS, KubeSpan, and pod-to-node traffic guidance

### compatibility

- No public module inputs or outputs were removed in this release
- Consumers applying the migrated Talos document patches should use Terraform Talos provider `0.12.0-alpha.5`; unsupported standalone `KubeNetworkConfig` and `KubeProxyConfig` documents are intentionally not used
- Existing `cilium-ipv4` and tunneled `cilium-ipv6` deployments remain available; encrypted native routing is opt-in through `cilium-ipv6-direct`

## [v4.1.0](https://github.com/miran248/terraform-talos-modules/compare/v4.0.1...v4.1.0) — 2026-07-17

### networking

- Updated Cilium from `v1.19.4` to `v1.19.6`
- Enabled eBPF host routing for IPv4 and IPv6 clusters; pod traffic now bypasses the host netfilter/iptables stack while retaining eBPF masquerading, kube-proxy replacement, and the netkit datapath
- Documented the Talos hostDNS requirement: Kubernetes DNS forwarding to hostDNS must remain disabled with Cilium eBPF host routing

### docs

- Added a hierarchical DOX `AGENTS.md` tree covering repository ownership, local contracts, workflows, and verification for modules, manifests, development environments, examples, local tooling, and image builds

## [v4.0.1](https://github.com/miran248/terraform-talos-modules/compare/v4.0.0...v4.0.1) — 2026-06-18

- **hcloud-csi** — removed hardcoded `hcloudVolumeDefaultLocation`; the CSI controller now auto-detects location from the node it runs on, supporting multi-region clusters without per-cluster config overrides
- Manifest dependency updates (coroot, gcp-wif-webhook, scaleway-csi)
- Release workflow renamed to `release.yaml`

## [v4.0.0](https://github.com/miran248/terraform-talos-modules/compare/v3.2.3...v4.0.0) — 2026-06-16

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
- Cilium `bpf.hostLegacyRouting: true` — fixes DNAT being skipped on the KubeSpan interface for established TCP flows in cross-cloud clusters
- Cilium BigTCP disabled — requires pending kernel support in VXLAN tunnel mode
- Cilium BBR disabled — incompatible with `bpf.hostLegacyRouting: true`
- All module resources consolidated into `main.tf` per module
- Upgraded talos provider to 0.12.x, hcloud, scaleway, and google providers upgraded

### manifests
- [cilium](manifests/cilium-ipv6) renamed to `cilium-ipv6`; `cilium-ipv4` added
- Added [cert-manager](manifests/cert-manager), [external-secrets](manifests/external-secrets), [scaleway-csi](manifests/scaleway-csi), [coroot](manifests/coroot) manifests
- Added [coredns-ipv4](manifests/coredns-ipv4) and [coredns-ipv6](manifests/coredns-ipv6) — CoreDNS with `hostNetwork: true` workaround (kept for reference, no longer required)
- [hcloud-csi](manifests/hcloud-csi) and [scaleway-csi](manifests/scaleway-csi) node DaemonSets scoped to their respective `provider` node label
- Cilium, ArgoCD, and other manifest dependencies updated

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
