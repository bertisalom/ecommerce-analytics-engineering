from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

import yaml


@dataclass(frozen=True)
class ColumnContract:
    name: str
    type: str


@dataclass(frozen=True)
class FileContract:
    file_name: str
    target_table: str
    columns: list[ColumnContract]


def load_contracts(contracts_path: Path) -> list[FileContract]:
    with contracts_path.open("r", encoding="utf-8") as handle:
        payload = yaml.safe_load(handle) or {}

    raw_contracts = payload.get("files")
    if not isinstance(raw_contracts, list) or not raw_contracts:
        raise ValueError("Contracts file must define a non-empty 'files' list.")

    contracts: list[FileContract] = []
    for item in raw_contracts:
        if not isinstance(item, dict):
            raise ValueError("Each file contract must be a mapping.")

        file_name = item.get("file_name")
        target_table = item.get("target_table")
        columns = item.get("columns")

        if not isinstance(file_name, str) or not file_name.endswith(".csv"):
            raise ValueError("Each contract must include a CSV file_name.")
        if not isinstance(target_table, str) or not target_table:
            raise ValueError(f"Contract for {file_name} must include a target_table.")
        if not isinstance(columns, list) or not columns:
            raise ValueError(f"Contract for {file_name} must include columns.")

        typed_columns: list[ColumnContract] = []
        for column in columns:
            if not isinstance(column, dict):
                raise ValueError(f"Contract for {file_name} has an invalid column entry.")

            name = column.get("name")
            field_type = column.get("type")
            if not isinstance(name, str) or not name:
                raise ValueError(f"Contract for {file_name} has a column without a name.")
            if not isinstance(field_type, str) or not field_type:
                raise ValueError(f"Contract for {file_name} has a column without a type.")

            typed_columns.append(ColumnContract(name=name, type=field_type))

        contracts.append(
            FileContract(
                file_name=file_name,
                target_table=target_table,
                columns=typed_columns,
            )
        )

    return contracts
