# Root commands for image build/push, testing, and Terraform deployment of Cloud Run workloads.

ifneq (,$(wildcard .env))
include .env
export
endif

IMAGE_TAG ?= $(shell git rev-parse HEAD)
INGESTION_IMAGE_TAG ?= $(IMAGE_TAG)
DBT_IMAGE_TAG ?= $(IMAGE_TAG)
TF_DIR ?= terraform/root

INGESTION_IMAGE_URI := $(GCP_REGION)-docker.pkg.dev/$(GCP_PROJECT_ID)/$(ARTIFACT_REGISTRY_REPOSITORY)/$(INGESTION_IMAGE_NAME):$(INGESTION_IMAGE_TAG)
DBT_IMAGE_URI := $(GCP_REGION)-docker.pkg.dev/$(GCP_PROJECT_ID)/$(ARTIFACT_REGISTRY_REPOSITORY)/$(DBT_IMAGE_NAME):$(DBT_IMAGE_TAG)

.PHONY: help \
	test-raw-upload test-ingestion test-all \
	print-ingestion-image print-dbt-image build-ingestion push-ingestion build-dbt push-dbt \
	tf-init tf-plan tf-apply

help:
	@echo "Available targets:"
	@echo "  test-raw-upload   Run raw upload unit tests"
	@echo "  test-ingestion    Run ingestion unit tests"
	@echo "  test-all          Run raw upload and ingestion unit tests"
	@echo "  print-ingestion-image  Print the fully qualified ingestion image URI"
	@echo "  print-dbt-image   Print the fully qualified dbt image URI"
	@echo "  build-ingestion   Build the ingestion image"
	@echo "  push-ingestion    Push the ingestion image"
	@echo "  build-dbt         Build the dbt image"
	@echo "  push-dbt          Push the dbt image"
	@echo "  tf-init           Initialize terraform/root"
	@echo "  tf-plan           Run terraform plan in terraform/root with ingestion and dbt image tags"
	@echo "  tf-apply          Run terraform apply in terraform/root with ingestion and dbt image tags"

test-raw-upload:
	.venv/bin/python -m pytest tests/unit/raw_upload/

test-ingestion:
	.venv/bin/python -m pytest tests/unit/ingestion/

test-all:
	.venv/bin/python -m pytest

print-ingestion-image:
	@echo $(INGESTION_IMAGE_URI)

print-dbt-image:
	@echo $(DBT_IMAGE_URI)

build-ingestion:
	docker buildx build --platform linux/amd64 -f cloud_run/ingestion/Dockerfile -t $(INGESTION_IMAGE_URI) --load .

push-ingestion:
	docker push $(INGESTION_IMAGE_URI)

build-dbt:
	docker buildx build --platform linux/amd64 -f cloud_run/dbt/Dockerfile -t $(DBT_IMAGE_URI) --load .

push-dbt:
	docker push $(DBT_IMAGE_URI)

tf-init:
	terraform -chdir=$(TF_DIR) init

tf-plan:
	TF_VAR_ingestion_image_tag=$(INGESTION_IMAGE_TAG) TF_VAR_dbt_image_tag=$(DBT_IMAGE_TAG) terraform -chdir=$(TF_DIR) plan

tf-apply:
	TF_VAR_ingestion_image_tag=$(INGESTION_IMAGE_TAG) TF_VAR_dbt_image_tag=$(DBT_IMAGE_TAG) terraform -chdir=$(TF_DIR) apply
