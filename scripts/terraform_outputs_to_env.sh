#!/usr/bin/env bash

set -euo pipefail

TF_DIR="${TF_DIR:-terraform/root}"

require_output() {
  local output_name="$1"
  terraform -chdir="$TF_DIR" output -raw "$output_name"
}

cat <<EOF
# Mirrored from Terraform outputs for local use.
GCP_PROJECT_ID=$(require_output project_id)
GCP_REGION=$(require_output region)
ARTIFACT_REGISTRY_REPOSITORY=$(require_output artifact_registry_repository)
INGESTION_IMAGE_NAME=$(require_output ingestion_image_name)
INGESTION_JOB_NAME=$(require_output ingestion_job_name)
DBT_IMAGE_NAME=$(require_output dbt_image_name)
DBT_JOB_NAME=$(require_output dbt_job_name)
RAW_BUCKET_NAME=$(require_output raw_bucket_name)
RAW_DATASET_ID=$(require_output raw_dataset_id)
STG_DATASET_ID=$(require_output stg_dataset_id)
INT_DATASET_ID=$(require_output int_dataset_id)
MART_DATASET_ID=$(require_output mart_dataset_id)
EOF
