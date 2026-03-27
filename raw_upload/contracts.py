from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

import yaml


@dataclass(frozen=True)
class FileContract:
    file_name: str
    target_table: str
    expected_columns: list[str]


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
        expected_columns = item.get("expected_columns")

        if not isinstance(file_name, str) or not file_name.endswith(".csv"):
            raise ValueError("Each contract must include a CSV file_name.")
        if not isinstance(target_table, str) or not target_table:
            raise ValueError(f"Contract for {file_name} must include a target_table.")
        if (
            not isinstance(expected_columns, list)
            or not expected_columns
            or not all(isinstance(column, str) and column for column in expected_columns)
        ):
            raise ValueError(f"Contract for {file_name} must include expected_columns.")
        contracts.append(
            FileContract(
                file_name=file_name,
                target_table=target_table,
                expected_columns=expected_columns,
            )
        )

    return contracts
