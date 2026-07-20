## Builds a reproducible tool that can regenerate your bundled
## ECCCClimateComposites.json whenever Env Canada updates its inventories  or
## normals.

from __future__ import annotations

import argparse
import csv
import zipfile
import time

from io import BytesIO, StringIO
from pathlib import Path
from typing import Any
from html.parser import HTMLParser
from urllib.parse import urlencode
from urllib.request import Request, urlopen

from generate_eccc_composite_catalog import (
    REQUIRED_COLUMNS,
    parse_station_inventory,
)

RESULTS_URL = (
    "https://climate.weather.gc.ca/"
    "climate_normals/"
    "results_1991_2020_e.html"
)

THREAD_DOWNLOAD_URL = (
    "https://climate.weather.gc.ca/"
    "climate_normals/"
    "thread_bulk_data_e.html"
)

DOWNLOAD_FORM_FIELDS = {
    "lang",
    "prov",
    "stnname",
    "yr",
    "stnID",
    "climate_id",
}

USER_AGENT = (
    "WeatherAPI-ECCC-Catalog-Builder/1.0"
)

def composite_anchors(
    station_inventory: dict[
        str,
        dict[str, Any],
    ],
) -> list[tuple[str, str]]:
    anchors: dict[str, str] = {}

    for (
        climate_identifier,
        inventory_record,
    ) in station_inventory.items():
        display_name = inventory_record[
            "compositeName"
        ]

        existing_identifier = anchors.get(
            display_name
        )

        if (
            existing_identifier is None
            or climate_identifier
            < existing_identifier
        ):
            anchors[display_name] = (
                climate_identifier
            )

    return sorted(
        anchors.items(),
        key=lambda item: (
            item[0],
            item[1],
        ),
    )

class ThreadDownloadFormParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__(
            convert_charrefs=True
        )

        self.inside_download_form = False
        self.fields: dict[str, str] = {}

    def handle_starttag(
        self,
        tag: str,
        attributes: list[
            tuple[str, str | None]
        ],
    ) -> None:
        attribute_dictionary = dict(
            attributes
        )

        if (
            tag == "form"
            and attribute_dictionary.get("id")
            == "dlt-data"
        ):
            self.inside_download_form = True
            return

        if (
            not self.inside_download_form
            or tag != "input"
        ):
            return

        name = attribute_dictionary.get("name")
        value = attribute_dictionary.get("value")

        if (
            name in DOWNLOAD_FORM_FIELDS
            and value is not None
        ):
            self.fields[name] = value

    def handle_endtag(
        self,
        tag: str,
    ) -> None:
        if (
            tag == "form"
            and self.inside_download_form
        ):
            self.inside_download_form = False


def resolve_download_fields(
    climate_identifier: str,
) -> dict[str, str]:
    query = urlencode(
        {
            "climate_id":
                climate_identifier,
            "dispBack": "0",
            "lstProvince": "",
            "searchType": "stnProv",
            "txtCentralLatMin": "0",
            "txtCentralLatSec": "0",
            "txtCentralLongMin": "0",
            "txtCentralLongSec": "0",
            "wbdisable": "true",
        }
    )

    request = Request(
        RESULTS_URL + "?" + query,
        headers={
            "User-Agent": USER_AGENT,
        },
    )

    with urlopen(
        request,
        timeout=60.0,
    ) as response:
        page_html = response.read().decode(
            "utf-8"
        )

    parser = ThreadDownloadFormParser()
    parser.feed(page_html)

    missing_fields = (
        DOWNLOAD_FORM_FIELDS
        - parser.fields.keys()
    )

    if missing_fields:
        raise ValueError(
            "ECCC download form is missing: "
            + ", ".join(
                sorted(missing_fields)
            )
        )

    resolved_identifier = parser.fields[
        "climate_id"
    ]

    if resolved_identifier != climate_identifier:
        raise ValueError(
            "ECCC resolved climate identifier "
            + resolved_identifier
            + " instead of "
            + climate_identifier
        )

    return parser.fields

## Makes the downloader rebust enough to survive downloading 448 Canadian stations
## over the internet. Without these functions, if the script dies at station #317, you'd have to start
## over. With them, the downloader becomes resumable.

## "Is this CSV actually a valid ECCC composite thread file? If so, which
## composite files does it belong?"

## CSV -> Correct columns? -> Contains rows? -> Every row has COMPOSITE_STATION_NAME?
## -> Do all rows belong to One composite? -> Return the composite name.

## If a CSV somehow looked like 'WINNIPEG WINNIPEG WINNIPEG' it returns 'WINNIPEG'.
## But if it somehow contained 'WINNIPEG TORONTO', it throws 'Value Error: Downloaded
## thread CSV contains multiple stations'.
def validated_thread_composite_name(
    csv_text: str,
    source_description: str,
) -> str:
    reader = csv.DictReader(
        StringIO(csv_text)
    )

    field_names = set(
        reader.fieldnames or []
    )

    missing_columns = (
        REQUIRED_COLUMNS - field_names
    )

    if missing_columns:
        raise ValueError(
            source_description
            + " is missing columns: "
            + ", ".join(
                sorted(missing_columns)
            )
        )

    rows = list(reader)

    if not rows:
        raise ValueError(
            source_description
            + " has no rows."
        )

    composite_names: set[str] = set()

    for row in rows:
        composite_name = (
            row.get(
                "COMPOSITE_STATION_NAME",
                ""
            )
            or ""
        ).strip()

        if not composite_name:
            raise ValueError(
                source_description
                + " has an empty composite name."
            )

        composite_names.add(
            composite_name
        )

    if len(composite_names) != 1:
        raise ValueError(
            source_description
            + " contains multiple composites: "
            + repr(
                sorted(composite_names)
            )
        )

    return next(
        iter(composite_names)
    )


def download_thread_csv(
    download_fields: dict[str, str],
    destination_directory: Path,
) -> Path:
    query_fields = dict(download_fields)

    query_fields["metathread"] = "threaddata"
    query_fields["submit_thread"] = "Download"

    request = Request(
        THREAD_DOWNLOAD_URL
        + "?"
        + urlencode(query_fields),
        headers={
            "User-Agent": USER_AGENT,
        },
    )

    with urlopen(
        request,
        timeout=60.0,
    ) as response:
        archive_data = response.read()

    try:
        with zipfile.ZipFile(
            BytesIO(archive_data)
        ) as archive:
            thread_members = [
                member
                for member in archive.infolist()
                if not member.is_dir()
                and member.filename
                    .lower()
                    .endswith(".csv")
                and "station_threads"
                    in member.filename.lower()
            ]

            if len(thread_members) != 1:
                raise ValueError(
                    "ECCC archive contains "
                    + str(len(thread_members))
                    + " station-thread CSV files."
                )

            member = thread_members[0]
            csv_data = archive.read(member)

    except zipfile.BadZipFile as error:
        raise ValueError(
            "ECCC returned an invalid ZIP archive."
        ) from error

    try:
        csv_text = csv_data.decode(
            "utf-8-sig"
        )
    except UnicodeDecodeError as error:
        raise ValueError(
            "ECCC thread CSV is not valid UTF-8."
        ) from error

    downloaded_name = (
        validated_thread_composite_name(
            csv_text,
            "Downloaded thread CSV",
        )
    )

    expected_name = download_fields[
        "stnname"
    ]

    if downloaded_name != expected_name:
        raise ValueError(
            "Downloaded thread belongs to "
            + downloaded_name
            + " instead of "
            + expected_name
        )

    destination_directory.mkdir(
        parents=True,
        exist_ok=True,
    )
    
    safe_filename = (
        member.filename
        .replace("\\", "_")
        .replace("/", "_")
    )

    destination_path = (
        destination_directory
        / safe_filename
    )

    if (
        destination_path.exists()
        and destination_path.read_bytes()
        == csv_data
    ):
        return destination_path

    temporary_path = (
        destination_path.with_suffix(
            destination_path.suffix + ".tmp"
        )
    )

    temporary_path.write_bytes(csv_data)
    temporary_path.replace(
        destination_path
    )

    return destination_path

def existing_composite_names(
    destination_directory: Path,
) -> set[str]:
    if not destination_directory.exists():
        return set()

    if not destination_directory.is_dir():
        raise ValueError(
            "Thread destination is not "
            "a directory: "
            + str(destination_directory)
        )

    existing_files = sorted(
        path
        for path in destination_directory.rglob(
            "*.csv"
        )
        if "station_threads"
            in path.name.lower()
    )

    names_to_paths: dict[str, Path] = {}

    for existing_file in existing_files:
        try:
            csv_text = existing_file.read_text(
                encoding="utf-8-sig"
            )
        except UnicodeDecodeError as error:
            raise ValueError(
                existing_file.name
                + " is not valid UTF-8."
            ) from error

        composite_name = (
            validated_thread_composite_name(
                csv_text,
                existing_file.name,
            )
        )

        previous_path = names_to_paths.get(
            composite_name
        )

        if previous_path is not None:
            raise ValueError(
                "Duplicate downloaded composite "
                + composite_name
                + ": "
                + previous_path.name
                + " and "
                + existing_file.name
            )

        names_to_paths[
            composite_name
        ] = existing_file

    return set(names_to_paths)

## Each tuple contains: (display_name, climate_identifier)
## destination_directory is where the official station-thread CSV files are saved.
## pause of 0.75 seconds so the script does not hammer ECCC's servers.
def download_all_threads(
    anchors: list[tuple[str, str]],
    destination_directory: Path,
    request_delay_seconds: float = 0.75,
    maximum_attempts: int = 3,
) -> list[Path]:

    ## A negative sleep duration would not make sense and would eventually
    ## cause time.sleep() to fail.
    if request_delay_seconds < 0.0:
        raise ValueError(
            "Request delay cannot be negative."
        )

    if maximum_attempts < 1:
        raise ValueError(
            "Maximum attempts must be positive."
        )
    
    ## Before making any network requests, the function scans the download directory
    ## and validates all existing thread CSVs.
    existing_names = (
        existing_composite_names(
            destination_directory
        )
    )
    
    ## downloaded_paths records files downloaded during this invocation. it does
    ## not include previously existing files that were skipped.
    downloaded_paths: list[Path] = []
    failure_messages: list[str] = []

    ## Unpacks each typle and gives it a human-redable counter.
    total_count = len(anchors)

    for index, (
        display_name,
        climate_identifier,
    ) in enumerate(
        anchors,
        start=1,
    ):
        progress = (
            "["
            + str(index)
            + "/"
            + str(total_count)
            + "] "
        )
        
        ## Skips existing composites.
        if display_name in existing_names:
            print(
                progress
                + "Already have "
                + display_name
            )
            continue

        succeeded = False

        for attempt in range(
            1,
            maximum_attempts + 1,
        ):
            try:
                download_fields = (
                    resolve_download_fields(
                        climate_identifier
                    )
                )

                resolved_name = download_fields[
                    "stnname"
                ]

                if resolved_name != display_name:
                    raise ValueError(
                        "Inventory calls this composite "
                        + display_name
                        + ", but ECCC resolved it as "
                        + resolved_name
                    )

                downloaded_path = (
                    download_thread_csv(
                        download_fields,
                        destination_directory,
                    )
                )

                downloaded_paths.append(
                    downloaded_path
                )

                existing_names.add(
                    display_name
                )

                print(
                    progress
                    + "Downloaded "
                    + display_name
                )

                succeeded = True
                break

            except (OSError, ValueError) as error:
                if attempt >= maximum_attempts:
                    failure_messages.append(
                        climate_identifier
                        + " "
                        + display_name
                        + ": "
                        + str(error)
                    )

                    print(
                        progress
                        + "Failed "
                        + display_name
                    )
                    break

                retry_delay_seconds = (
                    2.0
                    ** (attempt - 1)
                )

                print(
                    progress
                    + "Attempt "
                    + str(attempt)
                    + " failed; retrying in "
                    + str(retry_delay_seconds)
                    + " seconds."
                )

                time.sleep(
                    retry_delay_seconds
                )

        if (
            not succeeded
            and not failure_messages
        ):
            raise RuntimeError(
                "Downloader entered an invalid state."
            )

        if index < total_count:
            time.sleep(
                request_delay_seconds
            )
    ## After all composites have been attempted, this produces one complete error report
    ## rather than dying on the first problem.
    if failure_messages:
        raise RuntimeError(
            "Failed to download "
            + str(len(failure_messages))
            + " composites:\n"
            + "\n".join(failure_messages)
        )

    return downloaded_paths

def main() -> None:
    
    ## The user must provide the station inventory.
    argument_parser = argparse.ArgumentParser(
        description=(
            "Download official ECCC composite "
            "station-thread CSV files."
        )
    )
    
    ## The download directory. It tells the downloader where to place the 448
    ## source CSVs.
    argument_parser.add_argument(
        "station_inventory_csv",
        type=Path,
        help=(
            "Path to the ECCC national "
            "station inventory CSV."
        ),
    )

    argument_parser.add_argument(
        "destination_directory",
        type=Path,
        help=(
            "Directory where station-thread "
            "CSV files will be stored."
        ),
    )

    argument_parser.add_argument(
        "--delay-seconds",
        type=float,
        default=0.75,
        help=(
            "Delay between composite downloads. "
            "Defaults to 0.75 seconds."
        ),
    )

    argument_parser.add_argument(
        "--maximum-attempts",
        type=int,
        default=3,
        help=(
            "Maximum attempts per composite. "
            "Defaults to 3."
        ),
    )

    arguments = argument_parser.parse_args()

    station_inventory = (
        parse_station_inventory(
            arguments.station_inventory_csv
        )
    )

    anchors = composite_anchors(
        station_inventory
    )

    print(
        "Found "
        + str(len(anchors))
        + " official ECCC composites."
    )

    downloaded_paths = (
        download_all_threads(
            anchors,
            arguments.destination_directory,
            request_delay_seconds=
                arguments.delay_seconds,
            maximum_attempts=
                arguments.maximum_attempts,
        )
    )

    already_present_count = (
        len(anchors)
        - len(downloaded_paths)
    )

    print(
        "Download complete. "
        + str(len(downloaded_paths))
        + " downloaded; "
        + str(already_present_count)
        + " already present."
    )

if __name__ == "__main__":
    main()
