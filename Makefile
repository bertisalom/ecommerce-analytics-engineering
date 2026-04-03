# Lean local commands for testing, infra changes, and image rollout.

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

.PHONY: help test-all deploy-all tf-init tf-plan tf-apply

help:
	@echo "Available targets:"
	@echo "  test-all          Run raw upload and ingestion unit tests"
	@echo "  deploy-all        Push both images and roll out both Cloud Run jobs"
	@echo "  tf-init           Initialize terraform/root"
	@echo "  tf-plan           Run terraform plan in terraform/root for infra-only changes"
	@echo "  tf-apply          Run terraform apply in terraform/root for infra-only changes"

test-all:
	.venv/bin/python -m pytest

deploy-all:
	docker buildx build --platform linux/amd64 --provenance=false -f cloud_run/ingestion/Dockerfile -t $(INGESTION_IMAGE_URI) --push .
	docker buildx build --platform linux/amd64 --provenance=false -f cloud_run/dbt/Dockerfile -t $(DBT_IMAGE_URI) --push .
	gcloud run jobs update $(INGESTION_JOB_NAME) --project=$(GCP_PROJECT_ID) --region=$(GCP_REGION) --image=$(INGESTION_IMAGE_URI)
	gcloud run jobs update $(DBT_JOB_NAME) --project=$(GCP_PROJECT_ID) --region=$(GCP_REGION) --image=$(DBT_IMAGE_URI)

tf-init:
	terraform -chdir=$(TF_DIR) init

tf-plan:
	TF_VAR_ingestion_image_tag=$(INGESTION_IMAGE_TAG) TF_VAR_dbt_image_tag=$(DBT_IMAGE_TAG) terraform -chdir=$(TF_DIR) plan

tf-apply:
	TF_VAR_ingestion_image_tag=$(INGESTION_IMAGE_TAG) TF_VAR_dbt_image_tag=$(DBT_IMAGE_TAG) terraform -chdir=$(TF_DIR) apply
