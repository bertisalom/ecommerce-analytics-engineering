variable "project_id" {
  description = "GCP project ID."
  type        = string
}

variable "region" {
  description = "Primary region for this single-environment project."
  type        = string
}

variable "raw_bucket_name" {
  description = "Raw GCS bucket name."
  type        = string
}

variable "raw_dataset_id" {
  description = "BigQuery dataset ID for raw loaded tables."
  type        = string
  default     = "raw"
}

variable "stg_dataset_id" {
  description = "BigQuery dataset ID for staging models."
  type        = string
  default     = "stg"
}

variable "int_dataset_id" {
  description = "BigQuery dataset ID for intermediate models."
  type        = string
  default     = "int"
}

variable "mart_dataset_id" {
  description = "BigQuery dataset ID for mart models."
  type        = string
  default     = "mart"
}

variable "artifact_registry_repository" {
  description = "Artifact Registry repository for workload images."
  type        = string
  default     = "containers"
}

variable "ingestion_service_account_id" {
  description = "Service account ID for the ingestion workload."
  type        = string
  default     = "ingestion"
}

variable "dbt_service_account_id" {
  description = "Service account ID for the dbt workload."
  type        = string
  default     = "dbt"
}

variable "ingestion_job_name" {
  description = "Cloud Run job name for the ingestion workload."
  type        = string
  default     = "ingestion-job"
}

variable "ingestion_image_name" {
  description = "Artifact Registry image name for ingestion."
  type        = string
  default     = "ingestion"
}

variable "ingestion_image_tag" {
  description = "Artifact Registry image tag for ingestion."
  type        = string
}

variable "dbt_job_name" {
  description = "Cloud Run job name for the dbt workload."
  type        = string
  default     = "dbt"
}

variable "dbt_image_name" {
  description = "Artifact Registry image name for dbt."
  type        = string
  default     = "dbt"
}

variable "dbt_image_tag" {
  description = "Artifact Registry image tag for dbt."
  type        = string
}

variable "ingestion_job_timeout" {
  description = "Timeout for the ingestion Cloud Run job."
  type        = string
  default     = "600s"
}

variable "ingestion_job_max_retries" {
  description = "Maximum retries for the ingestion Cloud Run job."
  type        = number
  default     = 0
}

variable "dbt_job_timeout" {
  description = "Timeout for the dbt Cloud Run job."
  type        = string
  default     = "600s"
}

variable "dbt_job_max_retries" {
  description = "Maximum retries for the dbt Cloud Run job."
  type        = number
  default     = 0
}
