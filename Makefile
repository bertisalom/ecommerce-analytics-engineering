# Root commands for image build/push, testing, and Terraform deployment of Cloud Run workloads.

ifneq (,$(wildcard .env))
include .env
export
endif

PROJECT_ID ?= $(GCP_PROJECT_ID)
REGION ?= $(GCP_REGION)
ARTIFACT_REPOSITORY ?= ecommerce
INGESTION_IMAGE_NAME ?= ingestion
IMAGE_TAG ?= $(shell git rev-parse HEAD)

INGESTION_IMAGE_URI := $(REGION)-docker.pkg.dev/$(PROJECT_ID)/$(ARTIFACT_REPOSITORY)/$(INGESTION_IMAGE_NAME):$(IMAGE_TAG)

.PHONY: help \
	test-raw-upload test-ingestion test-all \
	print-ingestion-image build-ingestion push-ingestion \
	tf-init tf-plan tf-apply

help:
	@echo "Available targets:"
	@echo "  test-raw-upload   Run raw upload unit tests"
	@echo "  test-ingestion    Run ingestion unit tests"
	@echo "  test-all          Run raw upload and ingestion unit tests"
	@echo "  print-ingestion-image  Print the fully qualified ingestion image URI"
	@echo "  build-ingestion   Build the ingestion image"
	@echo "  push-ingestion    Push the ingestion image"
	@echo "  tf-init           Initialize terraform/root"
	@echo "  tf-plan           Run terraform plan in terraform/root with IMAGE_TAG"
	@echo "  tf-apply          Run terraform apply in terraform/root with IMAGE_TAG"

test-raw-upload:
	.venv/bin/python -m pytest tests/unit/raw_upload/

test-ingestion:
	.venv/bin/python -m pytest tests/unit/ingestion/

test-all:
	.venv/bin/python -m pytest

print-ingestion-image:
	@echo $(INGESTION_IMAGE_URI)

build-ingestion:
	docker buildx build --platform linux/amd64 -f cloud_run/ingestion/Dockerfile -t $(INGESTION_IMAGE_URI) --load .

push-ingestion:
	docker push $(INGESTION_IMAGE_URI)

tf-init:
	terraform -chdir=terraform/root init

tf-plan:
	TF_VAR_ingestion_image_tag=$(IMAGE_TAG) terraform -chdir=terraform/root plan

tf-apply:
	TF_VAR_ingestion_image_tag=$(IMAGE_TAG) terraform -chdir=terraform/root apply
