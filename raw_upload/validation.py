from __future__ import annotations

import csv
from pathlib import Path

from raw_upload.contracts import FileContract


def read_csv_header(file_path: Path) -> list[str]:
    with file_path.open("r", encoding="utf-8-sig", newline="") as handle:
        reader = csv.reader(handle)
        try:
            header = next(reader)
        except StopIteration as exc:
            raise ValueError(f"CSV file is empty: {file_path.name}") from exc

    normalized = [column.strip() for column in header]
    if not all(normalized):
        raise ValueError(f"CSV file contains blank header columns: {file_path.name}")

    return normalized


def validate_file(contract: FileContract, data_dir: Path) -> Path:
    file_path = data_dir / contract.file_name
    if not file_path.exists():
        raise FileNotFoundError(f"Expected file is missing: {contract.file_name}")

    actual_columns = read_csv_header(file_path)
    if actual_columns != contract.expected_columns:
        raise ValueError(
            f"Header mismatch for {contract.file_name}. "
            f"Expected {contract.expected_columns}, got {actual_columns}."
        )

    return file_path
