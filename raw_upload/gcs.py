from __future__ import annotations

from pathlib import Path

from google.cloud import storage

from raw_upload.contracts import FileContract


def build_object_name(contract: FileContract) -> str:
    return f"{contract.target_table}/{contract.file_name}"


def upload_file(bucket_name: str, file_path: Path, object_name: str) -> None:
    client = storage.Client()
    bucket = client.bucket(bucket_name)
    blob = bucket.blob(object_name)
    blob.upload_from_filename(str(file_path))
