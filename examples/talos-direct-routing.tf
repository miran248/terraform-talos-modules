# Use with manifests/cilium-ipv6-direct. Kubernetes allocates per-node /112
# PodCIDRs from fc00:1::/96, while KubeSpan advertises and carries them over
# WireGuard without VXLAN or an external cloud controller.
# The policy rules send pod traffic for node public allocations through
# KubeSpan table 180. Do not add node public routes to the main table; doing so
# can recursively capture WireGuard endpoints.
module "talos_direct_routing_cluster" {
  source = "github.com/miran248/terraform-talos-modules//modules/talos-cluster?ref=v4.2.4" # x-release-please-version

  # ... other inputs ...

  patches = {
    common = concat([
      <<-EOF
        apiVersion: v1alpha1
        kind: KubeSpanConfig
        enabled: true
        advertiseKubernetesNetworks: true
        allowDownPeerBypass: false
        harvestExtraEndpoints: false
        # Leave headroom below Cilium netkit/BPF's measured 1410-byte FIB
        # boundary on a 1500-byte IPv6 WireGuard underlay.
        mtu: 1400
        # Keep provider IPv4/CGNAT addresses host-accessible without allowing
        # KubeSpan to advertise or select them as WireGuard peer endpoints.
        filters:
          endpoints:
            - ::/0
        ---
        apiVersion: v1alpha1
        kind: LinkConfig
        name: kubespan
        routes:
          - destination: fc00:1::/96
            mtu: 1400
      EOF
      ,
      ], [
      for index, cidr in sort(distinct(flatten([
        # Include every node pool passed to the talos-cluster module.
        for pool in [module.paris_pool] : [
          for _, node in pool.nodes : node.ip_cidr
        ]
      ]))) : <<-EOF
          apiVersion: v1alpha1
          kind: RoutingRuleConfig
          name: "${1000 + index}"
          src: fc00:1::/96
          dst: ${cidr}
          table: "180"
          action: unicast
        EOF
    ])
  }
}
