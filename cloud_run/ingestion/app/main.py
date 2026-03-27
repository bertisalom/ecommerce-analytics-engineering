from __future__ import annotations

import logging
import uuid
from pathlib import Path

from google.cloud import bigquery

from cloud_run.ingestion.app.config import load_settings
from cloud_run.ingestion.app.loader import (
    append_temp_table_to_raw,
    build_gcs_uri,
    build_temp_table_id,
    delete_temp_table,
    ensure_final_table,
    load_gcs_file_to_temp_table,
)
from cloud_run.ingestion.app.schema_contracts import load_contracts


logger = logging.getLogger(__name__)
CONTRACTS_PATH = Path(__file__).resolve().parents[1] / "schema_contracts.yaml"


def configure_logging() -> None:
    logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")


def main() -> None:
    configure_logging()

    settings = load_settings()
    contracts = load_contracts(CONTRACTS_PATH)
    client = bigquery.Client(project=settings.gcp_project_id)
    ingestion_run_id = uuid.uuid4().hex

    logger.info("Starting ingestion run %s", ingestion_run_id)
    logger.info("Loaded %s file contracts from %s", len(contracts), CONTRACTS_PATH)

    for contract in contracts:
        gcs_uri = build_gcs_uri(settings.raw_bucket_name, contract)
        temp_table_id = build_temp_table_id(
            settings.gcp_project_id,
            settings.raw_dataset_id,
            contract.target_table,
            ingestion_run_id,
        )

        logger.info("Loading %s from %s", contract.target_table, gcs_uri)
        try:
            load_gcs_file_to_temp_table(
                client=client,
                gcs_uri=gcs_uri,
                temp_table_id=temp_table_id,
                contract=contract,
            )
            ensure_final_table(
                client=client,
                project_id=settings.gcp_project_id,
                dataset_id=settings.raw_dataset_id,
                contract=contract,
            )
            append_temp_table_to_raw(
                client=client,
                project_id=settings.gcp_project_id,
                dataset_id=settings.raw_dataset_id,
                contract=contract,
                temp_table_id=temp_table_id,
                ingestion_run_id=ingestion_run_id,
            )
            logger.info("Loaded %s into %s.%s", contract.file_name, settings.raw_dataset_id, contract.target_table)
        finally:
            delete_temp_table(client, temp_table_id)

    logger.info("Ingestion run %s completed successfully", ingestion_run_id)


if __name__ == "__main__":
    main()
