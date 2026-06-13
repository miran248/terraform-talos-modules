locals {
  oidc_bucket_url = "https://storage.googleapis.com/${google_storage_bucket.oidc.id}"

  service_accounts = { for a in var.service_accounts : a.name => a }

  roles = merge(flatten([
    for name, a in local.service_accounts : [
      for role in a.roles : {
        "${join("-", [name, role])}" : {
          name = name
          role = role
        }
      }
    ]
  ])...)

  ids = {
    oidc_bucket = google_storage_bucket.oidc.id
  }

  patches = {
    control_planes = [
      <<-EOF
        cluster:
          apiServer:
            extraArgs:
              api-audiences: "https://kubernetes.default.svc.cluster.local,iam.googleapis.com/${google_iam_workload_identity_pool_provider.oidc.name}"
              service-account-issuer: "${local.oidc_bucket_url}"
              service-account-jwks-uri: "${local.oidc_bucket_url}/openid/v1/jwks"
          serviceAccount:
            key: "${base64encode(tls_private_key.this.private_key_pem)}"
      EOF
    ]
  }
}

resource "google_storage_bucket" "oidc" {
  name          = var.bucket_name
  location      = var.bucket_location
  force_destroy = true
  storage_class = "NEARLINE"

  uniform_bucket_level_access = true

  soft_delete_policy {
    retention_duration_seconds = 0
  }

  versioning {
    enabled = false
  }
}
resource "google_storage_bucket_iam_member" "oidc" {
  bucket = google_storage_bucket.oidc.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "google_iam_workload_identity_pool" "this" {
  workload_identity_pool_id = var.name
}

resource "google_iam_workload_identity_pool_provider" "oidc" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.this.workload_identity_pool_id
  workload_identity_pool_provider_id = "${var.name}-oidc"

  attribute_mapping = {
    "google.subject" = "assertion.sub"
    "attribute.sub"  = "assertion.sub"
  }

  oidc {
    issuer_uri = local.oidc_bucket_url
    allowed_audiences = [
      "sts.googleapis.com",
    ]
  }
}

data "google_project" "this" {
}

resource "google_service_account" "this" {
  for_each   = local.service_accounts
  account_id = each.value.name
}
resource "google_project_iam_member" "this" {
  for_each = local.roles
  project  = data.google_project.this.project_id
  member   = google_service_account.this[each.value.name].member
  role     = each.value.role
}
resource "google_service_account_iam_member" "this" {
  for_each           = local.service_accounts
  service_account_id = google_service_account.this[each.key].name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principal://iam.googleapis.com/${google_iam_workload_identity_pool.this.name}/subject/system:serviceaccount:${each.value.subject}"
}
