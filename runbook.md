# Runbook

This runbook explains how to set up, bootstrap, deploy, and operate the project.

The project has two Cloud Run jobs:

- `ingestion-job`: loads validated files from GCS into append-only BigQuery `raw` tables
- `dbt-job`: runs `dbt build` to create `stg`, `int`, and `mart`

## Before You Start

You need these installed locally:

- Python
- Docker with `buildx`
- `gcloud`
- Terraform

You also need access to a GCP project where you can create:

- APIs
- service accounts and IAM bindings
- a GCS bucket
- BigQuery datasets
- Artifact Registry
- Cloud Run jobs

## Configuration Files

Create local config files first:

```bash
cp .env.example .env
cp terraform/root/terraform.tfvars.example terraform/root/terraform.tfvars
```

Treat `terraform/root/terraform.tfvars` as the canonical configuration. Local `.env` values should mirror the Terraform values that local commands need.

- Terraform is the source of truth for infrastructure names and IDs
- `.env` mirrors the subset of values needed by local commands, `raw_upload`, and the `Makefile`
- GitHub repository variables mirror the subset of values needed by CI and deploy
- Terraform outputs are the easiest way to confirm the final deployed values and keep the mirrored values aligned

For dbt specifically:

- `RAW_DATASET_ID` is the shared raw source dataset
- `STG_DATASET_ID`, `INT_DATASET_ID`, and `MART_DATASET_ID` are the Terraform-managed base model datasets
- `profiles.yml` uses a target-specific anchor dataset for the BigQuery profile
- local schema isolation comes from the shell `USER`
- in cloud, dbt builds into the fixed Terraform-managed base datasets
- locally, dbt builds into `<base_schema>_<user>`

Sync helpers:

- [`scripts/terraform_outputs_to_env.sh`](scripts/terraform_outputs_to_env.sh) prints mirrored local `.env` values from Terraform outputs
- [`scripts/terraform_outputs_to_github_actions.sh`](scripts/terraform_outputs_to_github_actions.sh) prints the GitHub Actions repository variables expected by CI and deploy

## Local Setup

Typical local setup:

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

The `Makefile` expects the virtual environment to live at `.venv`.

Authenticate locally:

```bash
gcloud auth login
gcloud auth application-default login
gcloud config set project <your-gcp-project-id>
gcloud auth configure-docker <your-region>-docker.pkg.dev
```

Check that the expected source files exist in `data/raw/` before continuing. The active ingestion contract currently covers:

- `category_translation.csv`
- `customers.csv`
- `order_items.csv`
- `orders.csv`
- `products.csv`
- `reviews.csv`

## Dependency Order For First-Time Setup

The first deployment has one important dependency:

- the Cloud Run jobs need container image URIs
- the container images need an Artifact Registry repository
- therefore Terraform cannot create the full Cloud Run stack until the repository exists and the first images have been pushed

That is why first-time setup happens in this order:

1. Initialize Terraform
2. Create Artifact Registry only
3. Build and push the first ingestion and dbt images
4. Apply the full Terraform stack
5. Upload raw files to GCS
6. Run ingestion
7. Run dbt

## First-Time Bootstrap

### 1. Initialize Terraform

```bash
make tf-init
```

### 2. Create Artifact Registry First

This is the only targeted apply required for first-time setup.

```bash
terraform -chdir=terraform/root apply \
  -target=google_artifact_registry_repository.containers
```

### 3. Build And Push The First Images

The current `Makefile` does not expose separate first-time build and push targets, so use the explicit Docker commands below for bootstrap.

Build and push the ingestion image:

```bash
docker buildx build \
  --platform linux/amd64 \
  --file cloud_run/ingestion/Dockerfile \
  --tag "${GCP_REGION}-docker.pkg.dev/${GCP_PROJECT_ID}/${ARTIFACT_REGISTRY_REPOSITORY}/${INGESTION_IMAGE_NAME}:$(git rev-parse HEAD)" \
  --push \
  .
```

Build and push the dbt image:

```bash
docker buildx build \
  --platform linux/amd64 \
  --file cloud_run/dbt/Dockerfile \
  --tag "${GCP_REGION}-docker.pkg.dev/${GCP_PROJECT_ID}/${ARTIFACT_REGISTRY_REPOSITORY}/${DBT_IMAGE_NAME}:$(git rev-parse HEAD)" \
  --push \
  .
```

### 4. Apply The Full Terraform Stack

Now Terraform can create the rest of the infrastructure, including the Cloud Run jobs that reference those images.

```bash
make tf-plan
make tf-apply
```

This creates or updates:

- required APIs
- the raw GCS bucket
- `raw`, `stg`, `int`, and `mart` BigQuery datasets
- service accounts for ingestion, dbt, CI, and deploy
- IAM bindings
- Cloud Run jobs
- GitHub Workload Identity Federation resources

After the full apply, you can print the mirrored local values from Terraform outputs:

```bash
scripts/terraform_outputs_to_env.sh
```

### 5. Upload Raw Files To GCS

Run the local upload only after the bucket exists.

```bash
python -m raw_upload.upload_to_gcs
```

This validates each CSV header against [`cloud_run/ingestion/schema_contracts.yaml`](cloud_run/ingestion/schema_contracts.yaml) before upload.

### 6. Run The Ingestion Job

```bash
gcloud run jobs execute "$INGESTION_JOB_NAME" \
  --region="$GCP_REGION" \
  --project="$GCP_PROJECT_ID" \
  --wait
```

### 7. Run The dbt Job

Run dbt only after raw data has been loaded.

```bash
gcloud run jobs execute "$DBT_JOB_NAME" \
  --region="$GCP_REGION" \
  --project="$GCP_PROJECT_ID" \
  --wait
```

## Normal Operating Flows

Use the flow that matches the kind of change you made.

### Infra-Only Changes

Use this when you changed Terraform but not the workload code.

```bash
make tf-plan
make tf-apply
```

### Workload Code Changes

Use this when you changed the ingestion code or dbt Cloud Run image and the jobs already exist.

```bash
make deploy-all
```

`deploy-all` builds and pushes both images, then updates both existing Cloud Run jobs.

### Raw Data Refresh

Use this when local files in `data/raw/` changed.

```bash
python -m raw_upload.upload_to_gcs

gcloud run jobs execute "$INGESTION_JOB_NAME" \
  --region="$GCP_REGION" \
  --project="$GCP_PROJECT_ID" \
  --wait

gcloud run jobs execute "$DBT_JOB_NAME" \
  --region="$GCP_REGION" \
  --project="$GCP_PROJECT_ID" \
  --wait
```

## Testing

Run Python unit tests locally:

```bash
make test-all
```

Run dbt locally if you want to validate the project before deploying. The committed [`dbt/profiles.yml`](dbt/profiles.yml) reads local settings from environment variables.

```bash
dbt deps --project-dir dbt --profiles-dir dbt
dbt parse --project-dir dbt --profiles-dir dbt
dbt build --project-dir dbt --profiles-dir dbt
```

## GitHub Actions Setup

After Terraform creates the WIF provider and service accounts, print the GitHub repository variables expected by CI and deploy:

```bash
scripts/terraform_outputs_to_github_actions.sh
```

Set the printed values as repository variables:

- `GCP_PROJECT_ID`
- `GCP_REGION`
- `ARTIFACT_REGISTRY_REPOSITORY`
- `RAW_DATASET_ID`
- `STG_DATASET_ID`
- `INT_DATASET_ID`
- `MART_DATASET_ID`
- `INGESTION_JOB_NAME`
- `INGESTION_IMAGE_NAME`
- `DBT_JOB_NAME`
- `DBT_IMAGE_NAME`
- `GCP_WIF_PROVIDER`
- `GCP_CI_SERVICE_ACCOUNT_EMAIL`
- `GCP_DEPLOY_SERVICE_ACCOUNT_EMAIL`

## Verification

After a successful run, verify:

- the raw bucket contains objects under table-aligned prefixes such as `orders/orders.csv`
- BigQuery `raw` tables contain landed rows plus ingestion metadata
- dbt built objects in `stg`, `int`, and `mart`
- Cloud Run job executions completed successfully

## Troubleshooting

- If the first full Terraform apply fails on Cloud Run image resolution, the first images were not pushed yet or were pushed with a different repository, image name, or tag than Terraform expects.
- If `raw_upload` fails, check `.env`, bucket name, GCP auth, and CSV headers.
- If `make deploy-all` fails, confirm the Cloud Run jobs already exist. It is not a first-time bootstrap command.
- If `make test-all` fails, confirm the virtual environment exists at `.venv` and dependencies are installed.
- If dbt fails, check that raw tables exist first and that `GCP_PROJECT_ID`, `GCP_REGION`, `RAW_DATASET_ID`, `STG_DATASET_ID`, `INT_DATASET_ID`, `MART_DATASET_ID`, and, for local development, `USER` are set correctly.
