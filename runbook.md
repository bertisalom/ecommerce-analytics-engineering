# Runbook

This runbook describes how to bootstrap, deploy, and execute the project workloads.

The project uses two Cloud Run jobs:

- `ingestion-job`
  Loads source files from GCS into append-only BigQuery `raw` tables.
- `dbt-job`
  Builds the dbt project from `raw` into `stg`, `int`, and `mart`.

## Local Setup

From a fresh clone, prepare the local environment first:

1. Clone the repository and move into the project directory.
2. Create and activate a virtual environment.
3. Install Python dependencies from `requirements.txt`.
4. Create `.env` from `.env.example`.
5. Create `terraform/root/terraform.tfvars` from `terraform/root/terraform.tfvars.example`.
6. Confirm the raw source files are present under `data/raw/`.
7. Authenticate `gcloud` for the target project.
8. Authenticate Docker to Artifact Registry for the target region.

Example local setup:

```bash
git clone <repo-url>
cd ecommerce-analytics-engineering

python -m venv .venv
source .venv/bin/activate

pip install -r requirements.txt

cp .env.example .env
cp terraform/root/terraform.tfvars.example terraform/root/terraform.tfvars

gcloud auth login
gcloud auth application-default login
gcloud config set project <your-gcp-project-id>
gcloud auth configure-docker $GCP_REGION-docker.pkg.dev
```

## Image And Repository Convention

The project uses one Artifact Registry repository and two workload images:

- repository: value provided through Terraform and environment configuration
- ingestion image: `ingestion`
- dbt image: `dbt`

By default, image tags come from the current git commit SHA through the `Makefile`.

## First-Time Bootstrap

On the first deployment, Terraform cannot fully create the Cloud Run jobs until
the workload images have been pushed to Artifact Registry. Because of that, the
initial setup is done in two phases.

This bootstrap flow is a one-time exception for initial provisioning. After the
first successful setup, use the normal workflow above.

### Phase 1: Bootstrap Artifact Registry

Initialize Terraform:

```bash
make tf-init
```

Create the Artifact Registry repository first:

```bash
terraform -chdir=terraform/root apply \
  -target=google_artifact_registry_repository.containers
```

This step is enough for the first image push because the immediate dependency is
the existence of the Artifact Registry repository. The remaining infrastructure
can be created in the full apply after the images are available.

This creates:

- Artifact Registry repository

### Phase 2: Build and push workload images

Build and push the ingestion image:

```bash
make build-ingestion
make push-ingestion
```

Build and push the dbt image:

```bash
make build-dbt
make push-dbt
```

### Phase 3: Apply full infrastructure

Now that the images exist, apply the full Terraform stack:

```bash
make tf-plan
make tf-apply
```

This creates or updates the Cloud Run jobs with image references that already exist in Artifact Registry.

### Phase 4: Upload raw source files to GCS

Before running the ingestion job for the first time, upload the local raw files into the raw bucket:

```bash
python -m raw_upload.upload_to_gcs
```

This is typically a one-time bootstrap step unless the local source files are replaced or refreshed.

### Phase 5: Execute Cloud Run jobs

Run the ingestion workload first:

```bash
gcloud run jobs execute ingestion-job --region=$GCP_REGION --project=$GCP_PROJECT_ID --wait
```

Then run the dbt workload:

```bash
gcloud run jobs execute dbt-job --region=$GCP_REGION --project=$GCP_PROJECT_ID --wait
```

## Normal Workflow

After the initial bootstrap, the standard operator flow is:

```bash
make build-ingestion
make push-ingestion

make build-dbt
make push-dbt

make tf-plan
make tf-apply
```

Before running `ingestion-job`, upload the raw source files into GCS if they are not already present in the raw bucket:

```bash
python -m raw_upload.upload_to_gcs
```

In the normal workflow, this usually remains a one-time initial load step and only needs to be repeated if the local source files change.

Then execute the jobs:

```bash
gcloud run jobs execute ingestion-job --region=$GCP_REGION --project=$GCP_PROJECT_ID --wait
gcloud run jobs execute dbt-job --region=$GCP_REGION --project=$GCP_PROJECT_ID --wait
```

## How The dbt Runtime Works

The dbt Cloud Run image is designed to stay thin:

- the root `dbt/` project is copied into the image
- `dbt deps` is baked into the image during Docker build
- the Cloud Run job only runs `dbt build`

This keeps runtime execution simpler and avoids package installation during job execution.

## Verification

After running the jobs:

- check Cloud Run execution status
- inspect Cloud Run logs if a job fails
- confirm raw tables loaded in BigQuery after `ingestion-job`
- confirm `stg`, `int`, and `mart` tables were built after `dbt`

## Troubleshooting

- If the first Terraform apply fails because Cloud Run cannot resolve an image, use the bootstrap flow above. The workload image must exist in Artifact Registry before the Cloud Run job can be created successfully.
- If image pushes fail, confirm Docker is authenticated to Artifact Registry for the target project and region.
- If the dbt job fails, inspect the Cloud Run execution logs first, then validate the local dbt project with `dbt parse` or `dbt build`.
