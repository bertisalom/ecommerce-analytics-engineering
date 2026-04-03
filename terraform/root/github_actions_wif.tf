resource "google_iam_workload_identity_pool" "github_actions" {
  workload_identity_pool_id = var.github_wif_pool_id
  display_name              = "GitHub Actions"
  description               = "OIDC trust for GitHub Actions workflows."
  project                   = var.project_id

  depends_on = [google_project_service.required]
}

resource "google_iam_workload_identity_pool_provider" "github_actions" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_actions.workload_identity_pool_id
  workload_identity_pool_provider_id = var.github_wif_provider_id
  display_name                       = "GitHub Actions"
  description                        = "OIDC provider for GitHub Actions workflows."
  project                            = var.project_id

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.ref"        = "assertion.ref"
    "attribute.repository" = "assertion.repository"
  }

  attribute_condition = "assertion.repository == '${var.github_owner}/${var.github_repository}'"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}
