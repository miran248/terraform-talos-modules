# talos-cluster
Generates Talos machine secrets, computes per-node config patches (cert SANs, etcd advertised subnets, hostname, aliases), and produces `user_data` configs for each node. Provider-agnostic - accepts outputs from any pool module.

## inputs

| name | type | required | description |
|---|---|---|---|
| `name` | `string` | yes | cluster name |
| `endpoint` | `string` | yes | cluster DNS endpoint or IP (e.g. `prod.example.com`) |
| `talos_version` | `string` | yes | Talos version (e.g. `v1.14.0`) |
| `kubernetes_version` | `string` | yes | Kubernetes version (e.g. `v1.36.1`) |
| `pools` | `list(`[hcloud-pool](../hcloud-pool) or [scaleway-pool](../scaleway-pool) outputs`)` | yes | all pools must have the same `mode` |
| `patches` | `patches` | no | cluster-wide config patches |

### patches fields

| name | type | description |
|---|---|---|
| `common` | `list(string)` | applied to all nodes |
| `control_planes` | `list(string)` | applied to control plane nodes only |
| `workers` | `list(string)` | applied to worker nodes only |

## outputs

| name | description |
|---|---|
| `name` | cluster name |
| `endpoint` | cluster endpoint |
| `cluster_endpoint` | full API server URL (`https://<endpoint>:6443`) |
| `nodes` | map of fully resolved node objects with patches and aliases |
| `configs` | map of rendered machine configurations (user_data), keyed by node name |
| `machine_secrets` | Talos machine secrets (sensitive) |
| `talos_config` | Talos client configuration (sensitive) |
| `talos_version` | Talos version |
| `kubernetes_version` | Kubernetes version |

## example

```hcl
module "talos_cluster" {
  source = "github.com/miran248/terraform-talos-modules//modules/talos-cluster?ref=v4.1.0"

  name               = "prod"
  endpoint           = "prod.example.com"
  talos_version      = "v1.14.0"
  kubernetes_version = "v1.36.1"

  pools = [
    module.nuremberg_pool,
    module.helsinki_pool,
  ]

  patches = {
    common = [
      <<-EOF
        cluster:
          network:
            cni:
              name: none
      EOF
      ,
      <<-EOF
        apiVersion: v1alpha1
        kind: ResolverConfig
        nameservers:
          - address: 2a00:1098:2b::1 # https://nat64.net
          - address: 2a00:1098:2c::1 # https://nat64.net
          - address: 2a01:4f8:c2c:123f::1 # https://nat64.net
      EOF
      ,
      <<-EOF
        apiVersion: v1alpha1
        kind: TimeSyncConfig
        ptp:
          devices:
            - /dev/ptp0
      EOF
      ,
    ]
    control_planes = [
      <<-EOF
        cluster:
          allowSchedulingOnControlPlanes: true
      EOF
      ,
    ]
  }
}
```
