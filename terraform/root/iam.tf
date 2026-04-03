resource "google_storage_bucket_iam_member" "ingestion_raw_viewer" {
  bucket = google_storage_bucket.raw.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.ingestion.email}"
}

resource "google_project_iam_member" "ingestion_bigquery_job_user" {
  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.ingestion.email}"
}

resource "google_bigquery_dataset_iam_member" "ingestion_raw_editor" {
  dataset_id = google_bigquery_dataset.raw.dataset_id
  project    = var.project_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${google_service_account.ingestion.email}"
}

resource "google_project_iam_member" "dbt_bigquery_job_user" {
  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.dbt.email}"
}

resource "google_bigquery_dataset_iam_member" "dbt_raw_viewer" {
  dataset_id = google_bigquery_dataset.raw.dataset_id
  project    = var.project_id
  role       = "roles/bigquery.dataViewer"
  member     = "serviceAccount:${google_service_account.dbt.email}"
}

resource "google_bigquery_dataset_iam_member" "dbt_stg_editor" {
  dataset_id = google_bigquery_dataset.stg.dataset_id
  project    = var.project_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${google_service_account.dbt.email}"
}

resource "google_bigquery_dataset_iam_member" "dbt_int_editor" {
  dataset_id = google_bigquery_dataset.int.dataset_id
  project    = var.project_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${google_service_account.dbt.email}"
}

resource "google_bigquery_dataset_iam_member" "dbt_mart_editor" {
  dataset_id = google_bigquery_dataset.mart.dataset_id
  project    = var.project_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${google_service_account.dbt.email}"
}

resource "google_project_iam_member" "ci_bigquery_user" {
  project = var.project_id
  role    = "roles/bigquery.user"
  member  = "serviceAccount:${google_service_account.ci.email}"
}

resource "google_bigquery_dataset_iam_member" "ci_raw_viewer" {
  dataset_id = google_bigquery_dataset.raw.dataset_id
  project    = var.project_id
  role       = "roles/bigquery.dataViewer"
  member     = "serviceAccount:${google_service_account.ci.email}"
}

resource "google_service_account_iam_member" "github_actions_wif_user" {
  service_account_id = google_service_account.ci.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_actions.name}/attribute.repository/${var.github_owner}/${var.github_repository}"
}

resource "google_artifact_registry_repository_iam_member" "deploy_artifact_registry_writer" {
  project    = var.project_id
  location   = var.region
  repository = google_artifact_registry_repository.containers.repository_id
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${google_service_account.deploy.email}"
}

resource "google_project_iam_member" "deploy_run_admin" {
  project = var.project_id
  role    = "roles/run.admin"
  member  = "serviceAccount:${google_service_account.deploy.email}"
}

resource "google_service_account_iam_member" "deploy_ingestion_service_account_user" {
  service_account_id = google_service_account.ingestion.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.deploy.email}"
}

resource "google_service_account_iam_member" "deploy_dbt_service_account_user" {
  service_account_id = google_service_account.dbt.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.deploy.email}"
}

resource "google_service_account_iam_member" "github_actions_wif_deploy_user" {
  service_account_id = google_service_account.deploy.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_actions.name}/attribute.repository/${var.github_owner}/${var.github_repository}"
}
