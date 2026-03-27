from pathlib import Path
from unittest.mock import Mock

from google.cloud import bigquery

from cloud_run.ingestion.app.loader import (
    build_final_table_schema,
    build_gcs_uri,
    build_temp_table_id,
    ensure_final_table,
)
from cloud_run.ingestion.app.schema_contracts import ColumnContract, FileContract, load_contracts


def test_build_gcs_uri_uses_table_prefix() -> None:
    contract = FileContract(
        file_name="orders.csv",
        target_table="orders",
        columns=[
            ColumnContract(name="order_id", type="STRING"),
            ColumnContract(name="customer_id", type="STRING"),
        ],
    )

    assert build_gcs_uri("ecommerce-analytics-eng-raw", contract) == (
        "gs://ecommerce-analytics-eng-raw/orders/orders.csv"
    )


def test_build_final_table_schema_appends_metadata_columns() -> None:
    contract = FileContract(
        file_name="orders.csv",
        target_table="orders",
        columns=[
            ColumnContract(name="order_id", type="STRING"),
            ColumnContract(name="customer_id", type="STRING"),
        ],
    )

    schema = build_final_table_schema(contract)

    assert [field.name for field in schema] == [
        "order_id",
        "customer_id",
        "ingested_at",
        "source_file_name",
        "ingestion_run_id",
    ]
    assert [field.field_type for field in schema[:2]] == ["STRING", "STRING"]


def test_build_temp_table_id_is_scoped_to_dataset_and_run() -> None:
    temp_table_id = build_temp_table_id(
        project_id="ecommerce-analytics-eng",
        dataset_id="raw",
        target_table="orders",
        ingestion_run_id="run123",
    )

    assert temp_table_id == "ecommerce-analytics-eng.raw._tmp_orders_run123"


def test_load_contracts_reads_typed_columns() -> None:
    contracts = load_contracts(Path("cloud_run/ingestion/schema_contracts.yaml"))
    orders_contract = next(contract for contract in contracts if contract.target_table == "orders")

    assert orders_contract.columns[0] == ColumnContract(name="order_id", type="STRING")
    assert orders_contract.columns[3] == ColumnContract(
        name="order_purchase_timestamp",
        type="TIMESTAMP",
    )


def test_ensure_final_table_sets_daily_partition_on_ingested_at() -> None:
    client = Mock()
    contract = FileContract(
        file_name="orders.csv",
        target_table="orders",
        columns=[
            ColumnContract(name="order_id", type="STRING"),
            ColumnContract(name="customer_id", type="STRING"),
        ],
    )

    ensure_final_table(
        client=client,
        project_id="ecommerce-analytics-eng",
        dataset_id="raw",
        contract=contract,
    )

    created_table = client.create_table.call_args.args[0]

    assert isinstance(created_table, bigquery.Table)
    assert created_table.time_partitioning is not None
    assert created_table.time_partitioning.field == "ingested_at"
    assert created_table.time_partitioning.type_ == bigquery.TimePartitioningType.DAY
