# talos-apply
Applies Talos machine configurations, bootstraps the cluster and retrieves the kubeconfig. Collects actual node IPs from apply module outputs to inject `StaticHostConfig` entries into each node's config.

Control planes are configured before workers when `kubernetes_version` or
`talos_version` changes on `talos-cluster`. Individual nodes within each group
may be configured concurrently by Terraform; HCP Terraform does not support a
custom CLI parallelism value.

`talos_version` selects the machine configuration contract. OS upgrades are
managed only when `installer_image` is explicitly supplied; changing the
configuration contract does not select an OS upgrade image.

Machine operations connect directly to each node IP, which must be reachable from
the Terraform runner. The shared cluster endpoint remains in use for cluster
bootstrap and kubeconfig retrieval. Talos maintenance mode ignores node-routing
metadata, so applying through a load balancer can configure the wrong backend.
The [provider client helper](https://github.com/siderolabs/terraform-provider-talos/blob/v0.12.0/pkg/talos/util.go#L517)
probes maintenance mode before trying authenticated operation.

Run `python3 tests/run.py` for the mocked endpoint regression test. The harness
replaces only the ephemeral drain credential lookup in a temporary copy because
Terraform does not support mocking ephemeral resources.

## inputs

| name | type | required | description |
|---|---|---|---|
| `cluster` | [talos-cluster](../talos-cluster) outputs | yes | |
| `applies` | `list(`[hcloud-apply](../hcloud-apply) or [scaleway-apply](../scaleway-apply) outputs`)` | yes | |
| `drain_on_upgrade` | `bool` | no | drain nodes before upgrading (default: `true`) |
| `installer_image` | `string` | no | Optional Talos installer image for OS upgrades, such as a custom image or dev build. Defaults to `null`, leaving the installed OS version unmanaged. |

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
  source = "github.com/miran248/terraform-talos-modules//modules/talos-apply?ref=v4.2.7" # x-release-please-version

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
