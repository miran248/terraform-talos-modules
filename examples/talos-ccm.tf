# talos-ccm requires additional patches to configure Kubernetes components
# to use an external cloud provider. Add these to your talos-cluster module.
#
# talos-ccm handles:
#   - node IPAM (CloudAllocator)
#   - Hetzner Cloud / Scaleway node metadata

module "talos_cluster" {
  source = "github.com/miran248/terraform-talos-modules//modules/talos-cluster?ref=v4.2.2"

  # ... other inputs ...

  patches = {
    common = [
      # ... other common patches ...
      <<-EOF
        machine:
          kubelet:
            extraArgs:
              cloud-provider: external
      EOF
      ,
    ]
    control_planes = [
      <<-EOF
        cluster:
          externalCloudProvider:
            enabled: true
        ---
        apiVersion: v1alpha1
        kind: KubeControllerManagerConfig
        extraArgs:
          cloud-provider: external
          allocate-node-cidrs: "false"
          controllers: "*,tokencleaner,-node-ipam-controller"
      EOF
      ,
    ]
  }
}
