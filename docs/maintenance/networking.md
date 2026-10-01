# Talos and Kubernetes networking contracts

## Address families and Talos

- Built-in Talos patches are complete per-family sets; never combine IPv4 and IPv6 pools.
- The built-in IPv6 KubeSpan endpoint filter advertises only IPv6 peers. Provider IPv4/CGNAT addresses remain host-accessible but cannot become WireGuard endpoints.
- Keep Kubernetes DNS forwarding to Talos hostDNS disabled with Cilium eBPF host routing.
- Review CNI, DNS, KubeSpan, API endpoints, node CIDR allocation, routing, and MTU as one system.

## Cilium profiles

- Keep IPv4 and IPv6 VXLAN profiles behaviorally aligned except for family-specific values.
- `cilium-ipv6-direct` is the encrypted native-routing profile over KubeSpan, scoped to Pod CIDR `fc00:1::/96` with BPF IPv6 masquerading only for off-cluster traffic.
- Keep eBPF host routing enabled and select `kubespan` as the direct-routing device.
- Restrict NodePort addresses to `::/0`; provider IPv4/CGNAT addresses must not enter the IPv6-only service datapath.
- All three profiles enable `bpf.masquerade: true`. This is separate from the agent option `enable-remote-node-masquerade`, which is not enabled by these profiles. Keep the latter disabled in the IPv6 direct-routing composition: earlier testing with it enabled observed invalid-source drops on pod-to-node traffic before Talos policy routing. This is a recorded integration finding, not a claim that BPF masquerading generally causes those drops. See [Cilium's distinction between BPF and remote-node masquerading](https://docs.cilium.io/en/stable/network/concepts/masquerading/).
- All three Cilium profiles install Gateway API CRDs and enable the Gateway controller. Gateway API is optional for basic cluster networking; it is enabled by our profiles and included in our dev acceptance tests for both IPv4 VXLAN and IPv6 native routing. Terraform provisioning alone does not install Cilium or Gateway API. Keep Envoy, L7 proxying, and iptables rule installation enabled for the configured Gateway support: Cilium refuses L7 startup without iptables rules. The earlier proxy-reconciliation workaround was removed after the complete direct-routing suite, including the Gateway HTTP-route test, passed with Talos `v1.15.0-alpha.0-dev.1` and Cilium `v1.19.6` on 2026-10-01; fresh dev3 subsequently passed both suites with Cilium `1.20.2`. BPF masquerading remains enabled independently.
- Keep Argo CD chart-managed NetworkPolicies disabled where networking policy is managed separately.

## Routing and MTU

- KubeSpan and the aggregate PodCIDR route use MTU 1420, the IPv6 WireGuard inner-packet ceiling on a 1500-byte underlay.
- `cilium-ipv6-direct` uses MTU 1400 for netkit/BPF headroom; live testing passed 1410-byte packets and dropped 1411-byte packets as `FIB lookup failed`.
- In the tested IPv6 direct-routing composition with BPF host routing, pod-to-node traffic uses destination-scoped Talos `RoutingRuleConfig` documents: source `fc00:1::/96`, destination each node public allocation, table `180`. This is a composition-specific contract, not a requirement for every Cilium installation.
- Never add node public `/128` routes to the main table; they can recursively capture WireGuard peer endpoints.
- Use built-in Kubernetes node CIDR allocation for direct-routing development, examples, and the local cluster unless a composition explicitly tests the cloud controller.

## IPv4 BPF/KubeSpan investigation

The official [Talos Cilium installation guide](https://docs.siderolabs.com/kubernetes-guides/cni/deploying-cilium)
does not prescribe custom pod-to-node routing rules or enable BPF masquerading
in its installation examples. Our VXLAN profile explicitly enables BPF
masquerading and BPF host routing. The [KubeSpan compatibility guidance](https://docs.siderolabs.com/talos/v1.14/networking/kubespan#cilium-compatibility-limitations)
warns about asymmetric routing and uses legacy host routing in its native-routing
example; its statement that default Cilium works is not a guarantee for our
modified BPF configuration. [Cilium documents](https://docs.cilium.io/en/stable/operations/performance/tuning/#ebpf-host-routing)
that BPF host routing bypasses host netfilter hooks.

On 2026-10-01, IPv4 worker-pod API requests timed out despite healthy Cilium
agents and health endpoints, including after an unchanged 15-minute wait and
upgrades to Cilium 1.20.2 and Kubernetes 1.36.5. Captures showed requests leaving
the public interface and replies returning over KubeSpan. A temporary rule
matching pod source `10.244.0.0/16` and one control-plane destination, using table
`180`, restored connectivity; removing it reproduced the timeout, and re-adding
it restored connectivity. The subsequent full IPv4 suite passed with rules for all four node destinations,
including Cilium health, pod API/DNS/egress, and Gateway traffic. This is our
selected netkit/BPF/KubeSpan integration workaround, not an upstream requirement.
Fresh dev3 subsequently passed both networking/Gateway suites on the same
versions, with the rules installed from its initial machine configuration. The difference from the
reported working Talos 1.14 deployment remains unproven.

### Routing mode versus host routing

Cilium's tunnel/native routing mode and BPF/legacy host-routing mode are
separate choices. VXLAN encapsulation does not imply that every pod-to-node
host-service connection is tunneled: in the observed IPv4 IP cache, remote pod
CIDRs had tunnel endpoints while the control-plane node IPs did not. The
compatibility concern is the interaction between BPF host routing and KubeSpan's
netfilter-based packet marking, not simply the selection of tunnel or native mode.

| Configuration | Evidence for custom pod-to-node policy rules |
| --- | --- |
| Upstream default Cilium tunnel setup with KubeSpan | No such rules prescribed by the official guides. |
| Our IPv4 VXLAN + BPF host routing + KubeSpan | Scoped rules fixed the minimal API reproduction; the full suite passed on upgraded dev2 and fresh dev3. |
| Our IPv6 native + BPF host routing + KubeSpan | Existing scoped rules are part of the passing composition, including the full suite on Cilium 1.20.2 and Kubernetes 1.36.5. |
| KubeSpan with legacy host routing | Earlier IPv4 testing passed without custom rules while retaining BPF masquerading. The official native-routing example also uses legacy host routing. |

The upgraded 1.20.2 comparison exposed another constraint: our profiles select
`bpf.datapathMode: netkit`. Setting `hostLegacyRouting: true` makes the agent fail
at startup with `netkit devices cannot be used with --enable-host-legacy-routing=true`.
That experiment was stopped on the deterministic error and BPF host routing
restored. The earlier legacy-routing result is not acceptance evidence for the
current netkit/1.20.2 combination. A legacy-routing alternative must also switch
to veth and should be tested on fresh nodes; preserving netkit requires BPF host
routing in this version.

Therefore, retaining BPF host routing with KubeSpan can require an explicit
pod-to-node routing workaround in either Cilium routing mode in our tested
topology; `RoutingRuleConfig` is not universally required, nor established as
the only solution. BPF host routing and BPF masquerading are distinct settings:
using legacy host routing does not itself require disabling BPF masquerading.

### Validation outcome — 2026-10-01

- The upgraded dev2 legacy-routing comparison was rejected at agent startup
  because netkit requires BPF host routing. A veth/legacy alternative remains
  a separate fresh-node test, not a convergence failure.
- BPF/netkit with scoped pod-to-node rules passed the full IPv4 suite on dev2.
  Fresh dev3 then passed both IPv4 VXLAN and IPv6 native suites, including
  health, policy rules, pod API/DNS/egress, IPv6 NAT64, and Gateway HTTP traffic.
- A simultaneous 15-second IPv4 worker capture observed VXLAN packets on
  `kubespan`, WireGuard packets on `eth0`, and no UDP/8472 packets on `eth0`.
  This confirms the encrypted underlay path for the sampled VXLAN traffic.
- Dev3 bootstrapped Kubernetes 1.36.5 on Talos `v1.15.0-alpha.0-dev.1`, then
  installed Cilium 1.20.2 and Gateway API 1.6.1. The [Terraform creation run](https://app.terraform.io/app/miran248/dev/runs/run-zuFxVEKQivWM9FUA)
  created all 68 resources in one apply, including both workload-identity
  publications. All eight nodes were Ready with correct hostname histories,
  and each cluster had three healthy voting etcd members. No node repair or
  in-place Kubernetes upgrade was needed.
- After acceptance, both dev3 clusters were destroyed with a reviewed targeted
  plan. Cloud and state checks confirmed removal of the test resources while
  retaining shared image/identity resources; source names were restored to dev1.
- These results accept the chosen composition; they do not establish why the
  earlier reported Talos 1.14 setup worked without this workaround.

## Cilium change validation

In-place changes are diagnostic experiments, not evidence of clean installation.
Use a complete rendered configuration, review its diff, and verify the effective
settings on every agent after rollout. Updating a ConfigMap alone does not prove
that running agents loaded it; [Cilium's configuration guide](https://docs.cilium.io/en/stable/network/kubernetes/configuration/)
requires agent restarts for configuration changes. With this repository's
Kustomize-rendered manifests, there is no Helm release whose values can be assumed
to represent the live state.

An agent restart preserves/restores datapath and endpoint state. Existing pods,
connections, NAT/conntrack entries, and configuration on disk can affect an
in-place comparison. Recreate disposable probe pods and use new connections after
each change. Verify endpoint regeneration and the loaded routing/masquerading
settings, rather than relying on DaemonSet readiness alone. A node reboot is
also not equivalent to a fresh installation because persistent state survives.

Supported Cilium version upgrades can be performed in place following the
[upgrade guide](https://docs.cilium.io/en/stable/operations/upgrade/), but proxy
traffic, including Gateway connections, can be disrupted. For major datapath
changes such as tunnel/native routing, address-family/IPAM changes, or veth/netkit
migration, prefer fresh disposable nodes/clusters for acceptance unless a specific
supported migration procedure is being tested. This is our testing policy, not
a claim that every such change universally requires cluster replacement.

Do not use `cleanState` or `cleanBpfState` as routine test preparation. Cilium
documents that BPF cleanup breaks existing load-balanced connections, and full
state cleanup removes endpoint state and requires endpoints to be recreated.
Use an explicit recovery procedure if needed; fresh dev3 nodes provide a clearer
acceptance test than repeated state purges on dev2.

For each configuration:

1. Finish the agent/operator rollout, confirm effective settings, and create
   fresh probe pods before measuring convergence. Record versions, settings,
   pod identities, and rollout completion time. Restart observation if settings
   change during the test.
2. Allow each failing connectivity check at least 15 minutes of unchanged
   configuration. Observe `cilium-dbg status`, `cilium-health status`,
   `cilium-dbg endpoint list`, Kubernetes/Cilium endpoints, and actual API/DNS/
   Gateway requests. The smoke script retries network checks and reports endpoint
   state counts once per minute; retain its output in a private log.
3. Diagnose in parallel with short, filtered `cilium-dbg monitor --type drop`
   captures (or Hubble if enabled), plus captures on the source and destination
   public/KubeSpan interfaces. Follow TCP SYN/SYN-ACK/ACK and retransmissions;
   include UDP DNS tests. Packet evidence can identify a mechanism earlier,
   but isolated drops or an empty monitor are not a final failure verdict.
   Connect `talosctl pcap` directly to the captured node (`-e` and `-n` both
   selecting that node) when capturing WireGuard traffic: proxying the capture
   stream through another KubeSpan peer can capture its own transport traffic.
4. A reproducible configuration rejection or deterministic incompatibility can
   fail early with its evidence recorded. Timeouts or incomplete convergence
   require the observation window. Success can be established sooner through
   repeated fresh connections, ready endpoints, and the full suite; repeat the
   chosen configuration on fresh dev3 before accepting it.
