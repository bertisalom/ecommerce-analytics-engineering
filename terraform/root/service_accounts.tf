resource "google_service_account" "ingestion" {
  account_id   = var.ingestion_service_account_id
  display_name = "Ingestion workload"
  project      = var.project_id

  depends_on = [google_project_service.required]
}

resource "google_service_account" "dbt" {
  account_id   = var.dbt_service_account_id
  display_name = "dbt workload"
  project      = var.project_id

  depends_on = [google_project_service.required]
}

resource "google_service_account" "ci" {
  account_id   = var.ci_service_account_id
  display_name = "GitHub Actions CI"
  project      = var.project_id

  depends_on = [google_project_service.required]
}

resource "google_service_account" "deploy" {
  account_id   = var.deploy_service_account_id
  display_name = "GitHub Actions Deploy"
  project      = var.project_id

  depends_on = [google_project_service.required]
}
