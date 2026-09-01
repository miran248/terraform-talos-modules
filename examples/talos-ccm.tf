# talos-ccm requires additional patches to configure Kubernetes components
# to use an external cloud provider. Add these to your talos-cluster module.
#
# talos-ccm handles:
#   - node IPAM (CloudAllocator)
#   - Hetzner Cloud / Scaleway node metadata

module "talos_cluster" {
  source = "github.com/miran248/terraform-talos-modules//modules/talos-cluster?ref=v4.2.7" # x-release-please-version

  # ... other inputs ...

  patches = {
    common = [
      # ... other common patches ...
      <<-EOF
        apiVersion: v1alpha1
        kind: KubeletConfig
        extraArgs:
          cloud-provider: external
      EOF
      ,
    ]
    control_planes = [
      # Talos 1.14 has no document resource for enabling an external cloud provider.
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
