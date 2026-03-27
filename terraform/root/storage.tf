resource "google_storage_bucket" "raw" {
  name                        = var.raw_bucket_name
  location                    = var.region
  project                     = var.project_id
  uniform_bucket_level_access = true

  depends_on = [google_project_service.required]
}
