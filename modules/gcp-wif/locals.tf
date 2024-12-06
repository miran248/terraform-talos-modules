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
