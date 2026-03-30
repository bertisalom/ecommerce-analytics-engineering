locals {
  ingestion_image_uri = "${var.region}-docker.pkg.dev/${var.project_id}/${var.artifact_registry_repository}/${var.ingestion_image_name}:${var.ingestion_image_tag}"
  dbt_image_uri       = "${var.region}-docker.pkg.dev/${var.project_id}/${var.artifact_registry_repository}/${var.dbt_image_name}:${var.dbt_image_tag}"
}

resource "google_cloud_run_v2_job" "ingestion" {
  name     = var.ingestion_job_name
  location = var.region
  project  = var.project_id
  deletion_protection = false

  template {
    template {
      service_account = google_service_account.ingestion.email
      max_retries     = var.ingestion_job_max_retries
      timeout         = var.ingestion_job_timeout

      containers {
        image = local.ingestion_image_uri

        env {
          name  = "GCP_PROJECT_ID"
          value = var.project_id
        }

        env {
          name  = "RAW_BUCKET_NAME"
          value = var.raw_bucket_name
        }

        env {
          name  = "RAW_DATASET_ID"
          value = var.raw_dataset_id
        }
      }
    }
  }

  depends_on = [
    google_project_service.required,
    google_artifact_registry_repository.containers,
    google_service_account.ingestion,
    google_storage_bucket.raw,
    google_bigquery_dataset.raw,
  ]
}

resource "google_cloud_run_v2_job_iam_member" "ingestion_executor" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_job.ingestion.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.ingestion.email}"
}

resource "google_cloud_run_v2_job" "dbt" {
  name                = var.dbt_job_name
  location            = var.region
  project             = var.project_id
  deletion_protection = false

  template {
    template {
      service_account = google_service_account.dbt.email
      max_retries     = var.dbt_job_max_retries
      timeout         = var.dbt_job_timeout

      containers {
        image = local.dbt_image_uri

        args = [
          "build",
        ]

        env {
          name  = "GCP_PROJECT_ID"
          value = var.project_id
        }

        env {
          name  = "RAW_DATASET_ID"
          value = var.raw_dataset_id
        }
      }
    }
  }

  depends_on = [
    google_project_service.required,
    google_artifact_registry_repository.containers,
    google_service_account.dbt,
    google_bigquery_dataset.raw,
    google_bigquery_dataset.stg,
    google_bigquery_dataset.int,
    google_bigquery_dataset.mart,
  ]
}

resource "google_cloud_run_v2_job_iam_member" "dbt_executor" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_job.dbt.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.dbt.email}"
}
