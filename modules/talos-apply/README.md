# talos-apply
Applies Talos machine configurations, bootstraps the cluster and retrieves the kubeconfig. Collects actual node IPs from apply module outputs to inject `StaticHostConfig` entries into each node's config.

Control planes are configured before workers when `kubernetes_version` or
`talos_version` changes on `talos-cluster`. Individual nodes within each group
may be configured concurrently by Terraform; HCP Terraform does not support a
custom CLI parallelism value.

## inputs

| name | type | required | description |
|---|---|---|---|
| `cluster` | [talos-cluster](../talos-cluster) outputs | yes | |
| `applies` | `list(`[hcloud-apply](../hcloud-apply) or [scaleway-apply](../scaleway-apply) outputs`)` | yes | |
| `drain_on_upgrade` | `bool` | no | drain nodes before upgrading (default: `true`) |
| `installer_image` | `string` | no | Talos installer image for OS upgrades. Defaults to `ghcr.io/siderolabs/installer:<talos_version>`. Override for custom schematics or dev builds. |

## outputs

| name | description |
|---|---|
| `kube_config` | Kubernetes client configuration (sensitive) |
| `ca_certificate` | Kubernetes CA certificate (sensitive) |
| `client_certificate` | Kubernetes client certificate (sensitive) |
| `client_key` | Kubernetes client key (sensitive) |

## example

```hcl
module "talos_apply" {
  source = "github.com/miran248/terraform-talos-modules//modules/talos-apply?ref=v4.1.0"

  cluster = module.talos_cluster
  applies = [module.nuremberg_apply, module.helsinki_apply]
}

output "talos_config" {
  value     = module.talos_cluster.talos_config
  sensitive = true
}
output "kube_config" {
  value     = module.talos_apply.kube_config
  sensitive = true
}
```
