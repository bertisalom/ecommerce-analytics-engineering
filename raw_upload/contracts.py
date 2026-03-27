from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

from cloud_run.ingestion.app.schema_contracts import load_contracts as load_ingestion_contracts


@dataclass(frozen=True)
class FileContract:
    file_name: str
    target_table: str
    expected_columns: list[str]


def load_contracts(contracts_path: Path) -> list[FileContract]:
    return [
        FileContract(
            file_name=contract.file_name,
            target_table=contract.target_table,
            expected_columns=[column.name for column in contract.columns],
        )
        for contract in load_ingestion_contracts(contracts_path)
    ]
