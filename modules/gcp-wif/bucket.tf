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
