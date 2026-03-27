from __future__ import annotations

from google.cloud import bigquery

from cloud_run.ingestion.app.schema_contracts import FileContract


METADATA_COLUMNS = (
    ("ingested_at", "TIMESTAMP"),
    ("source_file_name", "STRING"),
    ("ingestion_run_id", "STRING"),
)


def build_gcs_uri(bucket_name: str, contract: FileContract) -> str:
    return f"gs://{bucket_name}/{contract.target_table}/{contract.file_name}"


def build_source_schema(contract: FileContract) -> list[bigquery.SchemaField]:
    return [bigquery.SchemaField(column.name, column.type) for column in contract.columns]


def build_final_table_schema(contract: FileContract) -> list[bigquery.SchemaField]:
    source_columns = build_source_schema(contract)
    metadata = [bigquery.SchemaField(name, field_type) for name, field_type in METADATA_COLUMNS]
    return [*source_columns, *metadata]


def build_temp_table_id(
    project_id: str,
    dataset_id: str,
    target_table: str,
    ingestion_run_id: str,
) -> str:
    return f"{project_id}.{dataset_id}._tmp_{target_table}_{ingestion_run_id}"


def ensure_final_table(
    client: bigquery.Client,
    project_id: str,
    dataset_id: str,
    contract: FileContract,
) -> None:
    table_id = f"{project_id}.{dataset_id}.{contract.target_table}"
    table = bigquery.Table(table_id, schema=build_final_table_schema(contract))
    table.time_partitioning = bigquery.TimePartitioning(
        type_=bigquery.TimePartitioningType.DAY,
        field="ingested_at",
    )
    client.create_table(table, exists_ok=True)


def load_gcs_file_to_temp_table(
    client: bigquery.Client,
    gcs_uri: str,
    temp_table_id: str,
    contract: FileContract,
) -> None:
    job_config = bigquery.LoadJobConfig(
        source_format=bigquery.SourceFormat.CSV,
        skip_leading_rows=1,
        schema=build_source_schema(contract),
        write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE,
        allow_quoted_newlines=True,
    )
    client.load_table_from_uri(gcs_uri, temp_table_id, job_config=job_config).result()


def append_temp_table_to_raw(
    client: bigquery.Client,
    project_id: str,
    dataset_id: str,
    contract: FileContract,
    temp_table_id: str,
    ingestion_run_id: str,
) -> None:
    destination_table = f"{project_id}.{dataset_id}.{contract.target_table}"
    source_columns = ", ".join(f"`{column.name}`" for column in contract.columns)
    insert_columns = ", ".join(
        [*(f"`{column.name}`" for column in contract.columns), *(f"`{name}`" for name, _ in METADATA_COLUMNS)]
    )
    query = f"""
        INSERT INTO `{destination_table}` ({insert_columns})
        SELECT
            {source_columns},
            CURRENT_TIMESTAMP(),
            @source_file_name,
            @ingestion_run_id
        FROM `{temp_table_id}`
    """
    job_config = bigquery.QueryJobConfig(
        query_parameters=[
            bigquery.ScalarQueryParameter("source_file_name", "STRING", contract.file_name),
            bigquery.ScalarQueryParameter("ingestion_run_id", "STRING", ingestion_run_id),
        ]
    )
    client.query(query, job_config=job_config).result()


def delete_temp_table(client: bigquery.Client, temp_table_id: str) -> None:
    client.delete_table(temp_table_id, not_found_ok=True)
