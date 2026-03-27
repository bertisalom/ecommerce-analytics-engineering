from __future__ import annotations

import logging
import os
from pathlib import Path

from raw_upload.contracts import load_contracts
from raw_upload.gcs import build_object_name, upload_file
from raw_upload.validation import validate_file

PROJECT_ROOT = Path(__file__).resolve().parents[1]
DATA_DIR = PROJECT_ROOT / "data" / "raw"
CONTRACTS_PATH = PROJECT_ROOT / "raw_upload" / "file_contracts.yaml"

logger = logging.getLogger(__name__)


def configure_logging() -> None:
    logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")

def main() -> None:
    configure_logging()

    bucket_name = os.getenv("RAW_BUCKET_NAME")
    if not bucket_name:
        raise ValueError("RAW_BUCKET_NAME must be set in the environment.")

    contracts = load_contracts(CONTRACTS_PATH)
    uploaded_objects: list[str] = []

    logger.info("Starting raw upload to bucket %s", bucket_name)
    logger.info("Loaded %s file contracts from %s", len(contracts), CONTRACTS_PATH)

    try:
        for contract in contracts:
            logger.info("Validating %s", contract.file_name)
            file_path = validate_file(contract, DATA_DIR)

            object_name = build_object_name(contract)
            logger.info("Uploading %s to gs://%s/%s", file_path.name, bucket_name, object_name)
            upload_file(bucket_name, file_path, object_name)
            uploaded_objects.append(object_name)
            logger.info("Uploaded %s to gs://%s/%s", contract.file_name, bucket_name, object_name)
    except Exception:
        logger.exception("Raw upload failed.")
        raise

    logger.info("Upload complete. %s file(s) uploaded.", len(uploaded_objects))


if __name__ == "__main__":
    main()
