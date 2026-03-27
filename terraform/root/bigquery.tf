resource "google_bigquery_dataset" "raw" {
  dataset_id = var.raw_dataset_id
  project    = var.project_id
  location   = var.region

  depends_on = [google_project_service.required]
}

resource "google_bigquery_dataset" "stg" {
  dataset_id = var.stg_dataset_id
  project    = var.project_id
  location   = var.region

  depends_on = [google_project_service.required]
}

resource "google_bigquery_dataset" "int" {
  dataset_id = var.int_dataset_id
  project    = var.project_id
  location   = var.region

  depends_on = [google_project_service.required]
}

resource "google_bigquery_dataset" "mart" {
  dataset_id = var.mart_dataset_id
  project    = var.project_id
  location   = var.region

  depends_on = [google_project_service.required]
}
