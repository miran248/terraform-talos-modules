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
