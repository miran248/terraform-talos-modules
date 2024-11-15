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
