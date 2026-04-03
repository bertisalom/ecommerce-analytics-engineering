output "github_actions_wif_provider_name" {
  description = "Fully qualified Workload Identity Provider resource name for GitHub Actions authentication."
  value       = google_iam_workload_identity_pool_provider.github_actions.name
}

output "project_id" {
  description = "GCP project ID used by this deployment."
  value       = var.project_id
}

output "region" {
  description = "Primary GCP region used by this deployment."
  value       = var.region
}

output "raw_bucket_name" {
  description = "GCS bucket name used for raw file storage."
  value       = google_storage_bucket.raw.name
}

output "raw_dataset_id" {
  description = "BigQuery dataset ID used for append-only raw tables."
  value       = google_bigquery_dataset.raw.dataset_id
}

output "artifact_registry_repository" {
  description = "Artifact Registry repository for workload images."
  value       = google_artifact_registry_repository.containers.repository_id
}

output "ingestion_job_name" {
  description = "Cloud Run job name for ingestion."
  value       = google_cloud_run_v2_job.ingestion.name
}

output "ingestion_image_name" {
  description = "Artifact Registry image name for ingestion."
  value       = var.ingestion_image_name
}

output "dbt_job_name" {
  description = "Cloud Run job name for dbt."
  value       = google_cloud_run_v2_job.dbt.name
}

output "dbt_image_name" {
  description = "Artifact Registry image name for dbt."
  value       = var.dbt_image_name
}

output "github_actions_ci_service_account_email" {
  description = "Service account email used by GitHub Actions CI."
  value       = google_service_account.ci.email
}

output "github_actions_deploy_service_account_email" {
  description = "Service account email used by the GitHub Actions deploy workflow."
  value       = google_service_account.deploy.email
}
