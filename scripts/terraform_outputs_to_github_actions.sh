#!/usr/bin/env bash

set -euo pipefail

TF_DIR="${TF_DIR:-terraform/root}"

require_output() {
  local output_name="$1"
  terraform -chdir="$TF_DIR" output -raw "$output_name"
}

cat <<EOF
# GitHub Actions repository variables
GCP_PROJECT_ID=$(require_output project_id)
GCP_REGION=$(require_output region)
ARTIFACT_REGISTRY_REPOSITORY=$(require_output artifact_registry_repository)
RAW_DATASET_ID=$(require_output raw_dataset_id)
INGESTION_JOB_NAME=$(require_output ingestion_job_name)
INGESTION_IMAGE_NAME=$(require_output ingestion_image_name)
DBT_JOB_NAME=$(require_output dbt_job_name)
DBT_IMAGE_NAME=$(require_output dbt_image_name)
GCP_WIF_PROVIDER=$(require_output github_actions_wif_provider_name)
GCP_CI_SERVICE_ACCOUNT_EMAIL=$(require_output github_actions_ci_service_account_email)
GCP_DEPLOY_SERVICE_ACCOUNT_EMAIL=$(require_output github_actions_deploy_service_account_email)
EOF
