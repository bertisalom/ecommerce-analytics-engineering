# E-commerce Analytics Engineering on GCP

This project is an end-to-end analytics engineering portfolio project built on GCP. Its goal is to turn raw Brazilian e-commerce data into trusted, analytics-ready models that support business reporting and dashboarding.

The project is designed to demonstrate practical analytics engineering skills across ingestion, warehousing, transformation, testing, and infrastructure. It stays intentionally lean: the focus is on solving clear business problems with clean architecture, not on adding platform complexity for its own sake.

## Project Goal

The goal of this project is to build a reliable analytics pipeline that:

- ingests raw e-commerce source files into the cloud
- stores append-only raw data in BigQuery
- transforms raw data into clean and modular dbt models
- presents a dimensional reporting layer for dashboards and business analysis

The project is built to show how analytics engineering connects data platform design with business-facing reporting.

## Business Questions

The reporting layer is designed to answer four main questions:

1. How are orders, revenue, and delivery success trending over time?
2. Which product categories drive the most revenue, and which categories create poor customer experience?
3. How does delivery performance influence customer satisfaction?
4. How do new and returning customers differ in value and behavior?

These questions shape the modeling logic, the warehouse design, and the final business marts.

## Architecture

The pipeline follows a simple batch-oriented cloud workflow:

![Pipeline architecture](assets/architecture/pipeline-architecture.png)

Main components:

- `raw_upload/`
  Local validation and upload of source files into GCS.
- `cloud_run/ingestion/`
  Cloud Run job that loads source files from GCS into append-only BigQuery raw tables.
- `dbt/`
  Transformation layer that builds staging, intermediate, dimensional, and business reporting models.
- `cloud_run/dbt/`
  Thin Cloud Run runtime wrapper for executing dbt in batch mode.
- `terraform/root/`
  Infrastructure-as-code for datasets, bucket, IAM, Artifact Registry, and Cloud Run jobs.

## Data Modeling Approach

The warehouse follows a medallion-style structure with a dimensional core on top:

- `raw`
  Append-only ingestion tables in BigQuery.
- `stg`
  Source-aligned cleanup and deduplication.
- `int`
  Reusable business logic and order/customer enrichment.
- `mart`
  Final presentation layer split into dimensional core models and business marts.

Inside `mart`, the project uses:

- dimensional core models
  - `dim_customers`
  - `dim_products`
  - `fct_orders`
  - `fct_order_items`
- business marts
  - `mart_kpi_daily`
  - `mart_category_performance`
  - `mart_delivery_satisfaction`
  - `mart_customer_segments`

See [dbt/README.md](dbt/README.md) for a more detailed view of the transformation layer, model grains, and lineage.

This structure keeps the project easy to explain:

- staging handles cleaning
- intermediate models handle reusable logic
- facts and dimensions provide a stable analytical core
- marts answer business questions directly

## Source Data

The project uses the Brazilian E-Commerce Public Dataset by Olist.

Files in scope:

- `orders.csv`
- `order_items.csv`
- `reviews.csv`
- `customers.csv`
- `products.csv`
- `category_translation.csv`

## Tech Stack

- Python
- Google Cloud Storage
- BigQuery
- Cloud Run Jobs
- Artifact Registry
- dbt Core
- Terraform
- GitHub Actions

## Repository Structure

```text
data/raw/             Local source files
assets/               Shared documentation images and screenshots
raw_upload/           Local validation and upload to GCS
cloud_run/ingestion/  Cloud Run job for raw BigQuery ingestion
cloud_run/dbt/        Cloud Run runtime wrapper for dbt
dbt/                  dbt models, macros, tests, and configuration
terraform/root/       GCP infrastructure
tests/                Python unit tests
```

## How To Run

First-time setup is a two-step process:

1. bootstrap Artifact Registry so workload images can be pushed
2. build and push workload images, then apply Terraform so the full infrastructure and Cloud Run jobs can be created with real image references

Use [.env.example](.env.example) and [terraform.tfvars.example](terraform/root/terraform.tfvars.example) as setup references.

The detailed operator flow is documented in [runbook.md](runbook.md).

## Testing and Data Quality

The project includes:

- Python unit tests for upload and ingestion logic
- dbt schema tests for grain, nullability, relationships, and accepted values
- `dbt_utils` tests for composite keys and accepted ranges
- focused dbt singular tests for business invariants such as revenue consistency

## CI

The repository includes a lean GitHub Actions CI setup:

- `ci.yml`
  Runs Python unit tests, installs dbt packages, parses the dbt project, and checks Terraform formatting on pushes and pull requests.

## Design Choices

Several choices are intentional:

- raw tables are append-only so ingestion history is preserved
- deduplication is handled in dbt staging rather than ingestion code
- dbt transformations use deterministic full builds instead of incremental complexity
- Cloud Run is used for batch execution of both ingestion and dbt workloads
- IAM is scoped by workload so ingestion and dbt use separate service accounts with only the permissions required for their responsibilities
