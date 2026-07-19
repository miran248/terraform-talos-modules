# Use with manifests/cilium-ipv6-direct. Kubernetes allocates per-node /112
# PodCIDRs from fc00:1::/96, while KubeSpan advertises and carries them over
# WireGuard without VXLAN or an external cloud controller.
# Pods should use Services rather than remote node public IPs. Do not route node
# public /128s through kubespan; doing so can recursively capture its endpoints.
module "talos_direct_routing_cluster" {
  source = "github.com/miran248/terraform-talos-modules//modules/talos-cluster?ref=v4.2.0"

  # ... other inputs ...

  patches = {
    common = [
      <<-EOF
        apiVersion: v1alpha1
        kind: KubeSpanConfig
        enabled: true
        advertiseKubernetesNetworks: true
        allowDownPeerBypass: false
        harvestExtraEndpoints: false
        mtu: 1420
        ---
        apiVersion: v1alpha1
        kind: LinkConfig
        name: kubespan
        routes:
          - destination: fc00:1::/96
            mtu: 1420
      EOF
      ,
    ]
  }
}
