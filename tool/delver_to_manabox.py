#!/usr/bin/env python3
"""
Convert a DelverLens backup JSON file to a ManaBox-compatible CSV.

Usage:
    python3 tool/delver_to_manabox.py input.json output.csv [--no-api]

DelverLens backup files are JSON. The script handles both root formats:
  - A bare array:  [{...}, {...}]
  - An object:     {"version": 1, "cards": [{...}, ...]}

Cards that already carry a Scryfall ID are written directly. Cards without
one are looked up via the Scryfall API (set + collector number, then fuzzy
name) unless --no-api is passed, in which case they are skipped.

Required ManaBox columns produced:
  Name, Set code, Set name, Collector number, Foil, Rarity, Quantity,
  ManaBox ID, Scryfall ID, Purchase price, Misprint, Altered, Condition,
  Language, Purchase price currency
"""

from __future__ import annotations

import argparse
import csv
import json
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path


# ---------------------------------------------------------------------------
# ManaBox column layout (must match the order ManaBox expects)
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
# Condition mapping: DelverLens value → ManaBox value
# ---------------------------------------------------------------------------

# DelverLens stores conditions as short strings (NM, SP/LP, MP, HP, D) or
# sometimes as integers (0 = NM … 4 = Damaged).
_CONDITION_MAP: dict[str | int, str] = {
    # integer variants
    0: "near_mint",
    1: "lightly_played",
    2: "played",
    3: "poor",
    4: "poor",
    # string short-codes
    "nm": "near_mint",
    "m": "near_mint",
    "mint": "near_mint",
    "near_mint": "near_mint",
    "near mint": "near_mint",
    "lp": "lightly_played",
    "sp": "lightly_played",
    "ex": "lightly_played",
    "gd": "good",
    "vg": "good",
    "good": "good",
    "lightly_played": "lightly_played",
    "lightly played": "lightly_played",
    "slightly_played": "lightly_played",
    "slightly played": "lightly_played",
    "mp": "played",
    "played": "played",
    "moderately_played": "played",
    "moderately played": "played",
    "hp": "poor",
    "heavily_played": "poor",
    "heavily played": "poor",
    "d": "poor",
    "damaged": "poor",
    "poor": "poor",
}


def _map_condition(raw: object) -> str:
    if raw is None:
        return ""
    if isinstance(raw, int):
        return _CONDITION_MAP.get(raw, "")
    return _CONDITION_MAP.get(str(raw).strip().lower(), "")


def _map_foil(raw: object) -> str:
    """Map a DelverLens foil value to ManaBox normal / foil / etched."""
    if isinstance(raw, bool):
        return "foil" if raw else "normal"
    if isinstance(raw, str):
        v = raw.strip().lower()
        if v in ("true", "foil", "1", "yes"):
            return "foil"
        if v == "etched":
            return "etched"
    return "normal"


# ---------------------------------------------------------------------------
# Parsing helpers
# ---------------------------------------------------------------------------


def _extract_cards(data: object) -> list[dict]:
    """Return the list of card dicts regardless of the backup's root shape."""
    if isinstance(data, list):
        return data
    if isinstance(data, dict):
        for key in ("cards", "card", "collection", "items", "data"):
            if key in data and isinstance(data[key], list):
                return data[key]
    raise ValueError(
        "Could not find a card list in the backup. "
        "Expected a JSON array or an object with a 'cards' key."
    )


_UUID_RE_LEN = 36  # "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"


def _looks_like_uuid(value: str) -> bool:
    return len(value) == _UUID_RE_LEN and value.count("-") == 4


def _get_str(card: dict, *keys: str) -> str:
    """Return the first non-empty string among candidate keys."""
    for key in keys:
        v = card.get(key)
        if v is not None:
            s = str(v).strip()
            if s:
                return s
    return ""


def _get_scryfall_id(card: dict) -> str:
    """
    Extract the Scryfall UUID from a card dict.

    Prefers explicit scryfall-named keys; falls back to 'id' only when it
    looks like a UUID (36 chars, 4 hyphens) to avoid treating internal
    integer IDs as Scryfall IDs.
    """
    for key in ("scryfallId", "scryfall_id"):
        v = card.get(key)
        if v is not None:
            s = str(v).strip()
            if s:
                return s
    # Only accept 'id' when it matches UUID format
    v = card.get("id")
    if v is not None:
        s = str(v).strip()
        if s and _looks_like_uuid(s):
            return s
    return ""


def _get_quantity(card: dict) -> int:
    for key in ("quantity", "count", "qty", "amount"):
        v = card.get(key)
        if v is not None:
            try:
                return max(1, int(v))
            except (ValueError, TypeError):
                pass
    return 1


# ---------------------------------------------------------------------------
# Scryfall API lookups
# ---------------------------------------------------------------------------

_SCRYFALL_DELAY = 0.10  # 100 ms — Scryfall asks for ≤10 req/s


def _scryfall_get(url: str) -> dict | None:
    try:
        req = urllib.request.Request(
            url,
            headers={"User-Agent": "delver-to-manabox/1.0 (github.com/ryan-shah/bindermanager)"},
        )
        with urllib.request.urlopen(req, timeout=10) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as exc:
        if exc.code != 404:
            print(f"  [warn] Scryfall HTTP {exc.code}: {url}", file=sys.stderr)
        return None
    except Exception as exc:
        print(f"  [warn] Scryfall request failed: {exc}", file=sys.stderr)
        return None


def _lookup_scryfall(name: str, set_code: str, collector_number: str) -> dict | None:
    """
    Try to find a Scryfall card object. Prefers the precise
    /cards/{set}/{number} endpoint; falls back to fuzzy name search.
    """
    if set_code and collector_number:
        url = (
            "https://api.scryfall.com/cards/"
            f"{urllib.parse.quote(set_code.lower())}/"
            f"{urllib.parse.quote(collector_number)}"
        )
        time.sleep(_SCRYFALL_DELAY)
        result = _scryfall_get(url)
        if result and result.get("object") == "card":
            return result

    if name:
        params: dict[str, str] = {"fuzzy": name}
        if set_code:
            params["set"] = set_code
        url = "https://api.scryfall.com/cards/named?" + urllib.parse.urlencode(params)
        time.sleep(_SCRYFALL_DELAY)
        result = _scryfall_get(url)
        if result and result.get("object") == "card":
            return result

    return None


# ---------------------------------------------------------------------------
# Conversion
# ---------------------------------------------------------------------------


def convert(input_path: Path, output_path: Path, *, no_api: bool) -> None:
    raw_text = input_path.read_text(encoding="utf-8-sig")  # strips UTF-8 BOM
    data = json.loads(raw_text)
    cards = _extract_cards(data)

    rows: list[dict[str, object]] = []
    skipped = 0

    for i, card in enumerate(cards, start=1):
        scryfall_id = _get_scryfall_id(card)
        name         = _get_str(card, "name", "cardName", "card_name")
        set_code     = _get_str(card, "set", "setCode", "set_code", "edition", "editionCode")
        set_name     = _get_str(card, "setName", "set_name", "editionName", "edition_name")
        number       = _get_str(card, "number", "collectorNumber", "collector_number", "num")
        rarity       = _get_str(card, "rarity")
        language     = _get_str(card, "language", "lang")
        purchase_price = _get_str(card, "price", "purchasePrice", "purchase_price")

        quantity  = _get_quantity(card)
        foil      = _map_foil(card.get("foil", False))
        condition = _map_condition(card.get("condition", card.get("cond", card.get("grade"))))

        # Resolve Scryfall ID when absent
        if not scryfall_id:
            if no_api:
                label = name or f"card #{i}"
                print(f"  [skip] '{label}' has no Scryfall ID (--no-api)", file=sys.stderr)
                skipped += 1
                continue

            label = f"{name} ({set_code} #{number})" if (set_code or number) else name or f"card #{i}"
            print(f"  Looking up {label} ...", file=sys.stderr)

            sf = _lookup_scryfall(name, set_code, number)
            if sf:
                scryfall_id = sf.get("id", "")
                set_code    = set_code or sf.get("set", "")
                set_name    = set_name or sf.get("set_name", "")
                number      = number   or sf.get("collector_number", "")
                rarity      = rarity   or sf.get("rarity", "")
                name        = name     or sf.get("name", "")
            else:
                print(f"  [skip] Could not resolve '{label}'", file=sys.stderr)
                skipped += 1
                continue

        rows.append({
            "Name":                    name,
            "Set code":                set_code,
            "Set name":                set_name,
            "Collector number":        number,
            "Foil":                    foil,
            "Rarity":                  rarity,
            "Quantity":                quantity,
            "ManaBox ID":              "",
            "Scryfall ID":             scryfall_id,
            "Purchase price":          purchase_price or "0.00",
            "Misprint":                "false",
            "Altered":                 "false",
            "Condition":               condition,
            "Language":                language,
            "Purchase price currency": "USD",
        })

    output_path.parent.mkdir(parents=True, exist_ok=True)
    with output_path.open("w", newline="", encoding="utf-8") as fh:
        writer = csv.DictWriter(fh, fieldnames=MANABOX_HEADERS)
        writer.writeheader()
        writer.writerows(rows)

    print(f"\nWrote {len(rows)} row(s) to {output_path}", file=sys.stderr)
    if skipped:
        print(f"Skipped {skipped} card(s) with unresolvable Scryfall IDs.", file=sys.stderr)


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Convert a DelverLens backup JSON to a ManaBox-compatible CSV.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
DelverLens condition codes recognised
  Integers : 0=NM  1=LP  2=MP  3=HP  4=Damaged
  Strings  : NM SP LP EX GD VG MP HP D (case-insensitive)

ManaBox conditions produced
  near_mint  good  lightly_played  played  poor

Examples
  python3 tool/delver_to_manabox.py collection.json manabox.csv
  python3 tool/delver_to_manabox.py backup.json out.csv --no-api
""",
    )
    parser.add_argument("input",  type=Path, help="DelverLens backup (.json)")
    parser.add_argument("output", type=Path, help="Output ManaBox CSV path")
    parser.add_argument(
        "--no-api",
        action="store_true",
        help="Skip Scryfall lookups; cards without a Scryfall ID are skipped instead.",
    )
    args = parser.parse_args()

    if not args.input.exists():
        sys.exit(f"Error: input file not found: {args.input}")

    convert(args.input, args.output, no_api=args.no_api)


if __name__ == "__main__":
    main()
