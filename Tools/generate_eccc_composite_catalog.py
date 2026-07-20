#

# Offline csv parser written in python


from __future__ import annotations


import argparse
import csv
import json
import math

from datetime import date, datetime, timezone
from pathlib import Path
from typing import Any

MAXIMUM_ELEMENT = "DAILY MAXIMUM TEMPERATURE"

MINIMUM_ELEMENT = "DAILY MINIMUM TEMPERATURE"

SCHEMA_VERSION = 1

NORMAL_PERIOD_START_YEAR = 1991

NORMAL_PERIOD_END_YEAR = 2020

SOURCE_INVENTORY_URL = (
    "https://climate.weather.gc.ca/"
    "climate_normals/index_e.html"
)

INVENTORY_REQUIRED_COLUMNS = {
    "COMPOSITE_STATION_NAME",
    "STATION_NAME",
    "CLIMATE_ID",
    "LATITUDE",
    "LONGITUDE",
    "ELEVATION(m)",
}

REQUIRED_COLUMNS = {
    "COMPOSITE_STATION_NAME",
    "THREAD_SEQUENCE",
    "STATION_NAME",
    "CLIMATE_ID",
    "PROVINCE_OR_TERRITORY",
    "CLIMATE_ELEMENT",
    "DATA_INTERVAL",
    "EXTREME_FIRST_DATE",
    "FIRST_DATE",
    "LAST_DATE",
}

def cleaned(value: str | None) -> str | None:
    if value is None:
        return None
    
    result = value.strip()
    
    return result if result else None
    
def climate_date(
    raw_value: str | None,
) -> dict[str, int] | None:
    text = cleaned(raw_value)
    
    if text is None:
        return None
        
    try:
        parsed = date.fromisoformat(
            text.replace("/", "-")
        )
    except ValueError as error:
        raise ValueError(
            f"Invalid ECCC climate date: {text}"
        ) from error
        
    return {
        "year": parsed.year,
        "month": parsed.month,
        "day": parsed.day,
    }

def required_text(
    row: dict[str, str],
    column: str,
) -> str:
    value = cleaned(row.get(column))
    
    if value is None:
        raise ValueError(
            f"Missing required {column} value."
        )
        
    return value

def finite_number(
    text: str,
    column: str,
) -> float:
    try:
        value = float(text)
    except ValueError as error:
        raise ValueError(
            f"Invalid numeric {column} value: {text}"
        ) from error

    if not math.isfinite(value):
        raise ValueError(
            f"Non-finite {column} value: {text}"
        )

    return value


def required_number(
    row: dict[str, str],
    column: str,
) -> float:
    return finite_number(
        required_text(row, column),
        column,
    )


def optional_number(
    row: dict[str, str],
    column: str,
) -> float | None:
    text = cleaned(row.get(column))

    if text is None:
        return None

    return finite_number(text, column)


def parse_station_inventory(
    csv_path: Path,
) -> dict[str, dict[str, Any]]:
    inventory: dict[str, dict[str, Any]] = {}

    with csv_path.open(
        "r",
        encoding="utf-8-sig",
        newline="",
    ) as csv_file:
        reader = csv.DictReader(csv_file)

        field_names = set(
            reader.fieldnames or []
        )

        missing_columns = (
            INVENTORY_REQUIRED_COLUMNS
            - field_names
        )

        if missing_columns:
            raise ValueError(
                "Station inventory is missing columns: "
                + ", ".join(
                    sorted(missing_columns)
                )
            )

        for row in reader:
            climate_identifier = required_text(
                row,
                "CLIMATE_ID",
            )

            if climate_identifier in inventory:
                raise ValueError(
                    "Duplicate inventory climate identifier: "
                    + climate_identifier
                )

            latitude = required_number(
                row,
                "LATITUDE",
            )

            longitude = required_number(
                row,
                "LONGITUDE",
            )

            if not -90.0 <= latitude <= 90.0:
                raise ValueError(
                    f"Invalid latitude for {climate_identifier}."
                )

            if not -180.0 <= longitude <= 180.0:
                raise ValueError(
                    f"Invalid longitude for {climate_identifier}."
                )

            inventory[climate_identifier] = {
                "compositeName": required_text(
                    row,
                    "COMPOSITE_STATION_NAME",
                ),
                "stationName": required_text(
                    row,
                    "STATION_NAME",
                ),
                "coordinate": {
                    "latitude": latitude,
                    "longitude": longitude,
                },
                "elevationMeters": optional_number(
                    row,
                    "ELEVATION(m)",
                ),
            }

    if not inventory:
        raise ValueError(
            "Station inventory contains no stations."
        )

    return inventory

## Import one CSV row (a dictionary) and output another
## dictionary representing one validat
def thread_segment(
    row: dict[str, str],
) -> dict[str, Any]:
    sequence_text = required_text(
        row,
        "THREAD_SEQUENCE",
    )
    
    try:
        sequence = int(sequence_text)
    except ValueError as error:
        raise ValueError(
            "Invalid thread sequence: "
            + sequence_text
        ) from error
        
    if sequence <= 0:
        raise ValueError(
            "Thread sequences must be positive."
        )
    
    normal_start_date = climate_date(
        required_text(
            row,
            "FIRST_DATE",
        )
    )
    
    normal_end_date = climate_date(
        required_text(
            row,
            "LAST_DATE",
        )
    )
    
    if normal_start_date is None:
        raise ValueError(
            "A thread segment has no start date."
        )
    
    if normal_end_date is None:
        raise ValueError(
            "A thread segment has no end date."
        )
    
    return {
        "sequence": sequence,
        "stationName": required_text(
            row,
            "STATION_NAME",
        ),
        "climateIdentifier": required_text(
            row,
            "CLIMATE_ID",
        ),
        "normalStartDate": normal_start_date,
        "normalEndDate": normal_end_date,
        "longTermStartDate": climate_date(
            row.get("EXTREME_FIRST_DATE")
        ),
    }

def validated_segments(
    rows: list[dict[str, str]],
    element: str
) -> list[dict[str, Any]]:
    segments = [
        thread_segment(row)
        for row in rows
        if cleaned(row.get("CLIMATE_ELEMENT"))
        == element
        and cleaned(row.get("DATA_INTERVAL"))
        == "DAILY"
        and cleaned(row.get("FIRST_DATE"))
        is not None
        and cleaned(row.get("LAST_DATE"))
        is not None
    ]
    
    segments.sort(
        key=lambda segment: segment["sequence"]
    )
    
    if not segments:
        raise ValueError(
            f"No {element} thread was found."
        )
    
    source_sequences = [
        segment["sequence"]
        for segment in segments
    ]

    expected_source_sequences = list(
        range(
            source_sequences[0],
            source_sequences[0]
            + len(source_sequences),
        )
    )

    if (
        source_sequences
        != expected_source_sequences
    ):
        raise ValueError(
            f"{element} has invalid source "
            "sequence order: "
            + repr(source_sequences)
        )

    for normalized_sequence, segment in enumerate(
        segments,
        start=1,
    ):
        segment["sequence"] = (
            normalized_sequence
        )
        
    return segments
    
def parse_thread_csv(
    csv_path: Path,
    station_inventory: dict[
        str,
        dict[str, Any],
    ],
) -> dict[str, Any]:
    with csv_path.open(
        "r",
        encoding="utf-8-sig",
        newline="",
    ) as csv_file:
        reader = csv.DictReader(csv_file)
        
        field_names = set(
            reader.fieldnames or []
        )
        
        missing_columns = (
            REQUIRED_COLUMNS - field_names
        )
        
        if missing_columns:
            raise ValueError(
                "Thread CSV is missing columns: "
                + ", ".join(
                    sorted(missing_columns)
                )
            )
            
        rows = list(reader)
        
    if not rows:
        raise ValueError(
            "Thread CSV contains no rows."
        )
    
    display_names = {
        required_text(
            row,
            "COMPOSITE_STATION_NAME",
        )
        for row in rows
    }
    
    province_codes = {
        required_text(
            row,
            "PROVINCE_OR_TERRITORY",
        )
        for row in rows
    }
    
    if len(display_names) != 1:
        raise ValueError(
            "Thread CSV contains multiple "
            "composite station names."
        )
    
    if len(province_codes) != 1:
        raise ValueError(
            "Thread CSV contains multiple "
            "province codes."
        )
    
    maximum_segments = validated_segments(
        rows,
        MAXIMUM_ELEMENT,
    )
    
    minimum_segments = validated_segments(
        rows,
        MINIMUM_ELEMENT,
    )
    
    display_name = next(
        iter(display_names)
    )

    province_code = next(
        iter(province_codes)
    )
    
    all_temperature_segments = (
        maximum_segments
        + minimum_segments
    )
    
    for segment in all_temperature_segments:
        source_identifier = segment[
            "climateIdentifier"
        ]
        
        if source_identifier in station_inventory:
            continue
            
        station_name = segment[
            "stationName"
        ]
        
        matching_identifiers = sorted(
            inventory_identifier
            for(
                inventory_identifier,
                inventory_record
            ) in station_inventory.items()
            if (
                inventory_record["compositeName"]
                == display_name
                and inventory_record["stationName"]
                == station_name
            )
        )
        
        if len(matching_identifiers) != 1:
            raise ValueError(
                f"{display_name} thread station "
                f"{source_identifier} "
                f"({station_name}) is missing "
                "from the inventory and matched "
                + str(len(matching_identifiers))
                + " same-name inventory stations."
            )
        
        segment["climateIdentifier"] = (
            matching_identifiers[0]
        )

    thread_identifiers = {
        segment["climateIdentifier"]
        for segment in (
            maximum_segments
            + minimum_segments
        )
    }

    missing_identifiers = sorted(
        identifier
        for identifier in thread_identifiers
        if identifier not in station_inventory
    )

    if missing_identifiers:
        raise ValueError(
            f"{display_name} references stations "
            "missing from the inventory: "
            + ", ".join(missing_identifiers)
        )

    for identifier in thread_identifiers:
        inventory_record = (
            station_inventory[identifier]
        )

        if (
            inventory_record["compositeName"]
            != display_name
        ):
            raise ValueError(
                f"Inventory station {identifier} "
                f"belongs to "
                f"{inventory_record['compositeName']}, "
                f"not {display_name}."
            )

    canonical_identifier = (
        maximum_segments[0]
        ["climateIdentifier"]
    )

    canonical_station = (
        station_inventory[
            canonical_identifier
        ]
    )
    
    return {
        "canonicalClimateIdentifier":
            canonical_identifier,
        "displayName": display_name,
        "provinceCode": province_code,
        "coordinate":
            canonical_station["coordinate"],
        "elevationMeters":
            canonical_station["elevationMeters"],
        "maximumTemperatureThread": {
            "element": MAXIMUM_ELEMENT,
            "segments": maximum_segments,
        },
        "minimumTemperatureThread": {
            "element": MINIMUM_ELEMENT,
            "segments": minimum_segments,
        },
    }

def build_catalog(
    thread_directory: Path,
    station_inventory: dict[
        str,
        dict[str, Any],
    ],
) -> dict[str, Any]:
    if not thread_directory.is_dir():
        raise ValueError(
            "Thread directory does not exist: "
            + str(thread_directory)
        )

    thread_paths = sorted(
        path
        for path in thread_directory.rglob(
            "*.csv"
        )
        if "station_threads" in path.name.lower()
    )

    if not thread_paths:
        raise ValueError(
            "Thread directory contains no "
            "station-thread CSV files."
        )

    composites: list[dict[str, Any]] = []

    for thread_path in thread_paths:
        try:
            composite = parse_thread_csv(
                thread_path,
                station_inventory,
            )
        except ValueError as error:
            raise ValueError(
                f"{thread_path.name}: {error}"
            ) from error

        composites.append(composite)

    identifiers: set[str] = set()

    for composite in composites:
        identifier = composite[
            "canonicalClimateIdentifier"
        ]

        if identifier in identifiers:
            raise ValueError(
                "Duplicate composite identifier: "
                + identifier
            )

        identifiers.add(identifier)

    composites.sort(
        key=lambda composite: (
            composite["provinceCode"],
            composite["displayName"],
            composite[
                "canonicalClimateIdentifier"
            ],
        )
    )

    generated_at_utc = (
        datetime.now(timezone.utc)
        .replace(microsecond=0)
        .isoformat()
        .replace("+00:00", "Z")
    )

    return {
        "schemaVersion": SCHEMA_VERSION,
        "normalPeriodStartYear":
            NORMAL_PERIOD_START_YEAR,
        "normalPeriodEndYear":
            NORMAL_PERIOD_END_YEAR,
        "generatedAtUTC": generated_at_utc,
        "sourceInventoryURL":
            SOURCE_INVENTORY_URL,
        "composites": composites,
    }

def main() -> None:
    argument_parser = argparse.ArgumentParser(
        description=(
            "Build the bundled ECCC composite "
            "climate-station catalog."
        )
    )

    argument_parser.add_argument(
        "thread_directory",
        type=Path,
        help=(
            "Directory containing official ECCC "
            "station-thread CSV files."
        ),
    )

    argument_parser.add_argument(
        "station_inventory_csv",
        type=Path,
        help=(
            "Path to the ECCC national "
            "station inventory CSV."
        ),
    )

    argument_parser.add_argument(
        "output_json",
        type=Path,
        help=(
            "Destination for the generated "
            "catalog JSON."
        ),
    )

    arguments = argument_parser.parse_args()

    station_inventory = (
        parse_station_inventory(
            arguments.station_inventory_csv
        )
    )

    catalog = build_catalog(
        arguments.thread_directory,
        station_inventory,
    )

    serialized_catalog = (
        json.dumps(
            catalog,
            indent=2,
            ensure_ascii=False,
        )
        + "\n"
    )

    arguments.output_json.parent.mkdir(
        parents=True,
        exist_ok=True,
    )

    arguments.output_json.write_text(
        serialized_catalog,
        encoding="utf-8",
    )

    print(
        "Wrote "
        + str(len(catalog["composites"]))
        + " composites to "
        + str(arguments.output_json)
    )

if __name__ == "__main__":
    main()
