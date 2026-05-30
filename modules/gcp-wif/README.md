# gcp-wif
Manages GCP Workload Identity Federation resources: a workload identity pool, OIDC provider, service accounts, IAM bindings and a GCS bucket for OIDC discovery documents. Also generates Talos config patches that configure the cluster's OIDC issuer.

Use with [gcp-wif-apply](../gcp-wif-apply) to upload OIDC documents after the cluster is running.

## inputs

| name | type | description |
|---|---|---|
| `name` | `string` | workload identity pool name |
| `bucket_name` | `string` | GCS bucket name for OIDC discovery documents |
| `bucket_location` | `string` | GCS bucket location (e.g. `EU`) |
| `service_accounts` | `list(object)` | Kubernetes service accounts to federate |

### service account object fields

| name | type | description |
|---|---|---|
| `subject` | `string` | Kubernetes subject in `namespace:name` format |
| `name` | `string` | GCP service account name |
| `roles` | `list(string)` | GCP IAM roles to grant |

## outputs

| name | description |
|---|---|
| `name` | pool name |
| `bucket_name` | GCS bucket name |
| `ids` | resource IDs including `oidc_bucket` |
| `patches` | Talos config patches - pass `patches.control_planes` to `talos-cluster` |

## example

```hcl
module "gcp_wif" {
  source = "github.com/miran248/terraform-talos-modules//modules/gcp-wif?ref=v3.2.3"

  name            = "my-cluster"
  bucket_name     = "my-cluster-oidc"
  bucket_location = "EU"

  service_accounts = [
    {
      subject = "kube-system:cert-manager"
      name    = "cert-manager"
      roles   = ["roles/dns.admin"]
    },
  ]
}

module "talos_cluster" {
  source = "github.com/miran248/terraform-talos-modules//modules/talos-cluster?ref=v3.2.3"

  name               = "prod"
  endpoint           = "prod.example.com"
  talos_version      = "v1.13.3"
  kubernetes_version = "v1.36.1"

  pools = [
    module.nuremberg_pool,
  ]

  patches = {
    control_planes = module.gcp_wif.patches.control_planes
  }
}
```
