# gcp-wif
Manages GCP Workload Identity Federation resources: a workload identity pool, OIDC provider, service accounts, IAM bindings and a GCS bucket for OIDC discovery documents. Also generates Talos config patches that configure the cluster's OIDC issuer.

Use with [gcp-wif-apply](../gcp-wif-apply) to upload OIDC documents after the cluster is running.

## inputs

| name | type | required | description |
|---|---|---|---|
| `name` | `string` | yes | workload identity pool name |
| `bucket_name` | `string` | yes | GCS bucket name for OIDC discovery documents |
| `bucket_location` | `string` | yes | GCS bucket location (e.g. `EU`) |
| `service_accounts` | `list(service_account)` | no | Kubernetes service accounts to federate |

### service_account fields

| name | type | required | description |
|---|---|---|---|
| `subject` | `string` | yes | Kubernetes subject in `namespace:name` format |
| `name` | `string` | yes | GCP service account name |
| `roles` | `list(string)` | yes | GCP IAM roles to grant |

## outputs

| name | description |
|---|---|
| `name` | pool name |
| `bucket_name` | GCS bucket name |
| `ids` | resource IDs including `oidc_bucket` |
| `patches` | Talos config patches - pass `patches.control_planes` to [talos-cluster](../talos-cluster) |

## example

```hcl
module "gcp_wif" {
  source = "github.com/miran248/terraform-talos-modules//modules/gcp-wif?ref=v4.2.4" # x-release-please-version

  name            = "my-cluster"
  bucket_name     = "my-cluster-oidc"
  bucket_location = "EU"

  service_accounts = [
    { subject = "kube-system:cert-manager", name = "cert-manager", roles = ["roles/dns.admin"] },
  ]
}

module "talos_cluster" {
  source = "github.com/miran248/terraform-talos-modules//modules/talos-cluster?ref=v4.2.4" # x-release-please-version

  name               = "prod"
  endpoint           = "prod.example.com"
  talos_version      = "v1.14.0"
  kubernetes_version = "v1.36.1"

  pools = [
    module.nuremberg_pool,
  ]

  patches = {
    control_planes = module.gcp_wif.patches.control_planes
  }
}
```
