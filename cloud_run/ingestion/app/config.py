from __future__ import annotations

import os
from dataclasses import dataclass


@dataclass(frozen=True)
class Settings:
    gcp_project_id: str
    raw_bucket_name: str
    raw_dataset_id: str


def load_settings() -> Settings:
    gcp_project_id = os.getenv("GCP_PROJECT_ID")
    raw_bucket_name = os.getenv("RAW_BUCKET_NAME")
    raw_dataset_id = os.getenv("RAW_DATASET_ID")

    missing = [
        name
        for name, value in {
            "GCP_PROJECT_ID": gcp_project_id,
            "RAW_BUCKET_NAME": raw_bucket_name,
            "RAW_DATASET_ID": raw_dataset_id,
        }.items()
        if not value
    ]
    if missing:
        missing_names = ", ".join(missing)
        raise ValueError(f"Missing required environment variables: {missing_names}")

    return Settings(
        gcp_project_id=gcp_project_id,
        raw_bucket_name=raw_bucket_name,
        raw_dataset_id=raw_dataset_id,
    )
