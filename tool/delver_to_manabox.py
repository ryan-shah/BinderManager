#!/usr/bin/env python3
"""
Convert a DelverLens backup (.dlens SQLite) to a ManaBox-compatible CSV.

Usage:
    python3 tool/delver_to_manabox.py input.dlens output.csv
    python3 tool/delver_to_manabox.py input.dlens output.csv --include-decks

By default only cards in collection binders (lists.category = 1) are exported.
Pass --include-decks to also include cards assigned to deck lists (category = 2).

ManaBox columns produced:
    Name, Set code, Set name, Collector number, Foil, Rarity, Quantity,
    ManaBox ID, Scryfall ID, Purchase price, Misprint, Altered, Condition,
    Language, Purchase price currency
"""

from __future__ import annotations

import argparse
import csv
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

# DelverLens single-character rarity → ManaBox rarity string
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

# DelverLens full language name → ISO 639-1 / Scryfall language code
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

# DelverLens condition string → ManaBox condition string
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
    # Fall back to the first two characters lowercased (best-effort ISO code)
    return raw[:2].lower() if raw else "en"


def _map_condition(raw: str | None) -> str:
    return _CONDITION_MAP.get((raw or "").strip(), "")


def _map_foil(foil_int: int) -> str:
    return "foil" if foil_int else "normal"


# ---------------------------------------------------------------------------
# Conversion
# ---------------------------------------------------------------------------

_COLLECTION_QUERY = """\
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
FROM  cards       c
JOIN  data_cards  dc ON c.card      = dc._id
JOIN  data_names  dn ON dc.name     = dn._id
JOIN  data_editions de ON dc.edition = de._id
JOIN  lists        l  ON c.list     = l._id
{category_clause}
ORDER BY l.name, dn.name
"""


def convert(input_path: Path, output_path: Path, *, include_decks: bool) -> None:
    conn = sqlite3.connect(str(input_path))
    conn.row_factory = sqlite3.Row

    category_clause = "" if include_decks else "WHERE l.category = 1"
    query = _COLLECTION_QUERY.format(category_clause=category_clause)

    cur = conn.execute(query)

    rows: list[dict] = []
    missing_ids = 0

    for row in cur:
        scryfall_id = row["scryfall_id"] or ""
        if not scryfall_id:
            missing_ids += 1

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
            "Scryfall ID":             scryfall_id,
            "Purchase price":          f"{price:.2f}",
            "Misprint":                "false",
            "Altered":                 "false",
            "Condition":               _map_condition(row["condition"]),
            "Language":                _map_language(row["language"]),
            "Purchase price currency": "USD",
        })

    conn.close()

    output_path.parent.mkdir(parents=True, exist_ok=True)
    with output_path.open("w", newline="", encoding="utf-8") as fh:
        writer = csv.DictWriter(fh, fieldnames=MANABOX_HEADERS)
        writer.writeheader()
        writer.writerows(rows)

    print(f"Wrote {len(rows)} row(s) to {output_path}", file=sys.stderr)
    if missing_ids:
        print(
            f"Warning: {missing_ids} row(s) have no Scryfall ID — "
            "they will show as unmatched in ManaBox.",
            file=sys.stderr,
        )


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Convert a DelverLens .dlens backup to a ManaBox-compatible CSV.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Foil    : cards.foil 0→normal  1→foil
Rarity  : C→common  U→uncommon  R→rare  M→mythic  S→special  B→bonus
Language: full name (e.g. 'Japanese') → ISO code (e.g. 'ja'); '' → 'en'
Condition: NM/LP/MP/HP/D strings → ManaBox near_mint/lightly_played/played/poor

Examples:
  python3 tool/delver_to_manabox.py 2024_Dec_01_backup.dlens manabox.csv
  python3 tool/delver_to_manabox.py collection.dlens out.csv --include-decks
""",
    )
    parser.add_argument("input",  type=Path, help="DelverLens backup (.dlens SQLite file)")
    parser.add_argument("output", type=Path, help="Output ManaBox CSV path")
    parser.add_argument(
        "--include-decks",
        action="store_true",
        help="Also export cards in deck lists (default: collection binders only)",
    )
    args = parser.parse_args()

    if not args.input.exists():
        sys.exit(f"Error: input file not found: {args.input}")

    convert(args.input, args.output, include_decks=args.include_decks)


if __name__ == "__main__":
    main()
