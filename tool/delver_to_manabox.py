#!/usr/bin/env python3
"""
Convert a DelverLens backup (.dlens SQLite) to ManaBox-compatible CSV(s).

Usage:
    # Collection only (default)
    python3 tool/delver_to_manabox.py input.dlens output.csv

    # Collection + merge all decks into one file
    python3 tool/delver_to_manabox.py input.dlens output.csv --include-decks

    # Collection file + one CSV per deck in a directory
    python3 tool/delver_to_manabox.py input.dlens output.csv --decks-dir ./decks/

    # Both flags: merged file AND individual deck files
    python3 tool/delver_to_manabox.py input.dlens output.csv --include-decks --decks-dir ./decks/

ManaBox columns produced:
    Name, Set code, Set name, Collector number, Foil, Rarity, Quantity,
    ManaBox ID, Scryfall ID, Purchase price, Misprint, Altered, Condition,
    Language, Purchase price currency
"""

from __future__ import annotations

import argparse
import csv
import re
import sqlite3
import sys
from pathlib import Path

# ---------------------------------------------------------------------------
# ManaBox column layout
# ---------------------------------------------------------------------------

MANABOX_HEADERS = [
    "Name",
    "Set code",
    "Set name",
    "Collector number",
    "Foil",
    "Rarity",
    "Quantity",
    "ManaBox ID",
    "Scryfall ID",
    "Purchase price",
    "Misprint",
    "Altered",
    "Condition",
    "Language",
    "Purchase price currency",
]

# ---------------------------------------------------------------------------
# Value mappings
# ---------------------------------------------------------------------------

_RARITY_MAP: dict[str, str] = {
    "C": "common",
    "U": "uncommon",
    "R": "rare",
    "M": "mythic",
    "S": "special",
    "B": "bonus",
    "T": "token",
    "L": "land",
}

_LANGUAGE_MAP: dict[str, str] = {
    "":                    "en",
    "English":             "en",
    "Chinese Simplified":  "zhs",
    "Chinese Traditional": "zht",
    "French":              "fr",
    "German":              "de",
    "Italian":             "it",
    "Japanese":            "ja",
    "Korean":              "ko",
    "Portuguese":          "pt",
    "Russian":             "ru",
    "Spanish":             "es",
}

_CONDITION_MAP: dict[str, str] = {
    "":                  "",
    "M":                 "near_mint",
    "NM":                "near_mint",
    "Mint":              "near_mint",
    "Near Mint":         "near_mint",
    "LP":                "lightly_played",
    "SP":                "lightly_played",
    "EX":                "lightly_played",
    "Lightly Played":    "lightly_played",
    "Slightly Played":   "lightly_played",
    "GD":                "good",
    "VG":                "good",
    "Good":              "good",
    "MP":                "played",
    "Played":            "played",
    "Moderately Played": "played",
    "HP":                "poor",
    "Heavily Played":    "poor",
    "D":                 "poor",
    "Damaged":           "poor",
    "Poor":              "poor",
}


def _map_rarity(raw: str | None) -> str:
    return _RARITY_MAP.get(raw or "", "")


def _map_language(raw: str | None) -> str:
    raw = (raw or "").strip()
    if raw in _LANGUAGE_MAP:
        return _LANGUAGE_MAP[raw]
    return raw[:2].lower() if raw else "en"


def _map_condition(raw: str | None) -> str:
    return _CONDITION_MAP.get((raw or "").strip(), "")


def _map_foil(foil_int: int) -> str:
    return "foil" if foil_int else "normal"


def _safe_filename(name: str) -> str:
    """Sanitize a deck name into a safe filename (no path separators or special chars)."""
    safe = re.sub(r'[\\/:*?"<>|]', "_", name).strip().strip(".")
    return safe or "unnamed"


# ---------------------------------------------------------------------------
# Database access
# ---------------------------------------------------------------------------

_CARD_QUERY = """\
SELECT
    dn.name                                              AS name,
    de.tl_abb                                            AS set_code,
    de.name                                              AS set_name,
    dc.number                                            AS collector_number,
    dc.rarity                                            AS rarity,
    c.foil                                               AS foil,
    c.quantity                                           AS quantity,
    c.condition                                          AS condition,
    c.language                                           AS language,
    c.price_acquired                                     AS price_acquired,
    COALESCE(NULLIF(c.scryfall_id, ''), dc.scryfall_id) AS scryfall_id
FROM  cards        c
JOIN  data_cards   dc ON c.card      = dc._id
JOIN  data_names   dn ON dc.name     = dn._id
JOIN  data_editions de ON dc.edition = de._id
JOIN  lists         l  ON c.list     = l._id
WHERE {filter}
ORDER BY dn.name
"""


def _fetch_rows(conn: sqlite3.Connection, filter_sql: str, params: tuple = ()) -> list[dict]:
    query = _CARD_QUERY.format(filter=filter_sql)
    rows: list[dict] = []
    for row in conn.execute(query, params):
        price = row["price_acquired"] or 0.0
        rows.append({
            "Name":                    row["name"] or "",
            "Set code":                row["set_code"] or "",
            "Set name":                row["set_name"] or "",
            "Collector number":        row["collector_number"] or "",
            "Foil":                    _map_foil(row["foil"] or 0),
            "Rarity":                  _map_rarity(row["rarity"]),
            "Quantity":                row["quantity"] or 1,
            "ManaBox ID":              "",
            "Scryfall ID":             row["scryfall_id"] or "",
            "Purchase price":          f"{price:.2f}",
            "Misprint":                "false",
            "Altered":                 "false",
            "Condition":               _map_condition(row["condition"]),
            "Language":                _map_language(row["language"]),
            "Purchase price currency": "USD",
        })
    return rows


def _write_csv(rows: list[dict], path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as fh:
        writer = csv.DictWriter(fh, fieldnames=MANABOX_HEADERS)
        writer.writeheader()
        writer.writerows(rows)


def _warn_missing_ids(rows: list[dict], label: str) -> None:
    missing = sum(1 for r in rows if not r["Scryfall ID"])
    if missing:
        print(
            f"  Warning: {missing} row(s) in '{label}' have no Scryfall ID"
            " — they will show as unmatched in ManaBox.",
            file=sys.stderr,
        )


# ---------------------------------------------------------------------------
# Entry points
# ---------------------------------------------------------------------------


def export_collection(conn: sqlite3.Connection, output_path: Path, *, include_decks: bool) -> None:
    """Write all collection (and optionally deck) cards to a single CSV."""
    if include_decks:
        filter_sql = "1=1"
    else:
        filter_sql = "l.category = 1"

    rows = _fetch_rows(conn, filter_sql)
    _write_csv(rows, output_path)
    label = "collection + decks" if include_decks else "collection"
    print(f"Collection: wrote {len(rows)} row(s) to {output_path}", file=sys.stderr)
    _warn_missing_ids(rows, label)


def export_decks(conn: sqlite3.Connection, decks_dir: Path) -> None:
    """Write one CSV per deck list (lists.category = 2) into decks_dir."""
    decks = conn.execute(
        "SELECT _id, name FROM lists WHERE category = 2 ORDER BY name"
    ).fetchall()

    if not decks:
        print("No deck lists found in backup.", file=sys.stderr)
        return

    decks_dir.mkdir(parents=True, exist_ok=True)
    print(f"Decks: exporting {len(decks)} list(s) to {decks_dir}/", file=sys.stderr)

    for deck in decks:
        deck_id: int = deck["_id"]
        deck_name: str = deck["name"] or f"deck_{deck_id}"

        rows = _fetch_rows(conn, "l._id = ?", (deck_id,))
        filename = _safe_filename(deck_name) + ".csv"
        out_path = decks_dir / filename
        _write_csv(rows, out_path)
        print(f"  {deck_name}: {len(rows)} card(s) → {filename}", file=sys.stderr)
        _warn_missing_ids(rows, deck_name)


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Convert a DelverLens .dlens backup to ManaBox-compatible CSV(s).",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Foil     : 0→normal  1→foil
Rarity   : C→common  U→uncommon  R→rare  M→mythic  S→special  B→bonus
Language : full name (e.g. 'Japanese') → ISO code (e.g. 'ja'); '' → 'en'
Condition: NM/LP/MP/HP/D → near_mint/lightly_played/played/poor

Examples:
  # Collection only
  python3 tool/delver_to_manabox.py backup.dlens collection.csv

  # Collection merged with all decks
  python3 tool/delver_to_manabox.py backup.dlens everything.csv --include-decks

  # Collection file + one CSV per deck
  python3 tool/delver_to_manabox.py backup.dlens collection.csv --decks-dir ./decks/

  # Both: merged file AND individual deck files
  python3 tool/delver_to_manabox.py backup.dlens everything.csv --include-decks --decks-dir ./decks/
""",
    )
    parser.add_argument("input",  type=Path, help="DelverLens backup (.dlens SQLite file)")
    parser.add_argument("output", type=Path, help="Output ManaBox CSV for the collection")
    parser.add_argument(
        "--include-decks",
        action="store_true",
        help="Also merge deck list cards into the main output CSV",
    )
    parser.add_argument(
        "--decks-dir",
        type=Path,
        metavar="DIR",
        help="Directory to write one CSV per deck list (created if needed)",
    )
    args = parser.parse_args()

    if not args.input.exists():
        sys.exit(f"Error: input file not found: {args.input}")

    conn = sqlite3.connect(str(args.input))
    conn.row_factory = sqlite3.Row

    export_collection(conn, args.output, include_decks=args.include_decks)

    if args.decks_dir:
        export_decks(conn, args.decks_dir)

    conn.close()


if __name__ == "__main__":
    main()
