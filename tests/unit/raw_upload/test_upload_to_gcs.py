from pathlib import Path

import pytest

from raw_upload.contracts import FileContract, load_contracts
from raw_upload.gcs import build_object_name
from raw_upload.validation import validate_file


def test_load_contracts_includes_orders_contract() -> None:
    contracts = load_contracts(Path("cloud_run/ingestion/schema_contracts.yaml"))
    orders_contract = next(contract for contract in contracts if contract.file_name == "orders.csv")

    assert orders_contract.target_table == "orders"
    assert orders_contract.expected_columns == [
        "order_id",
        "customer_id",
        "order_status",
        "order_purchase_timestamp",
        "order_approved_at",
        "order_delivered_carrier_date",
        "order_delivered_customer_date",
        "order_estimated_delivery_date",
    ]


def test_build_object_name_uses_table_prefix() -> None:
    contract = FileContract(
        file_name="orders.csv",
        target_table="orders",
        expected_columns=["order_id", "customer_id"],
    )

    assert build_object_name(contract) == "orders/orders.csv"


def test_validate_file_accepts_real_orders_file() -> None:
    contract = FileContract(
        file_name="orders.csv",
        target_table="orders",
        expected_columns=[
            "order_id",
            "customer_id",
            "order_status",
            "order_purchase_timestamp",
            "order_approved_at",
            "order_delivered_carrier_date",
            "order_delivered_customer_date",
            "order_estimated_delivery_date",
        ],
    )

    file_path = validate_file(contract, Path("data/raw"))

    assert file_path.name == "orders.csv"


def test_validate_file_accepts_bom_encoded_header() -> None:
    contract = FileContract(
        file_name="category_translation.csv",
        target_table="category_translation",
        expected_columns=[
            "product_category_name",
            "product_category_name_english",
        ],
    )

    file_path = validate_file(contract, Path("data/raw"))

    assert file_path.name == "category_translation.csv"


def test_validate_file_raises_for_header_mismatch(tmp_path: Path) -> None:
    csv_path = tmp_path / "orders.csv"
    csv_path.write_text("wrong,columns\n1,2\n", encoding="utf-8")

    contract = FileContract(
        file_name="orders.csv",
        target_table="orders",
        expected_columns=["order_id", "customer_id"],
    )

    with pytest.raises(ValueError, match="Header mismatch"):
        validate_file(contract, tmp_path)
