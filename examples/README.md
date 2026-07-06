# Examples

Reusable fixtures for in-browser acceptance passes (see the "Verify"
section of `design/PHASE4_HANDOFF.md`). Known-good as of **2026-07-05**.

## `acceptance_collection.csv`

A ManaBox-format collection CSV crafted against the **debug quick-import
corpus** — the onboarding screen's "Quick import — 5,000 cards (debug)"
option, which imports the first ~5,000 entries of Scryfall's
default-cards bulk file. Every row uses a **real Scryfall ID** taken from
the first ~60 entries of that file, so all rows match after a quick
import.

What's in it, by purpose:

| Cards | Purpose |
| --- | --- |
| Mystical Tutor ×2 nonfoil + ×1 foil (dmr 421) | D13 cheapest-finish rule: reserving via a deck must consume the cheap nonfoil stack and leave the foil idle/allocatable |
| Birds of Paradise, Narset, Temporal Manipulation (all ≥ $10) | Populate a `usd>=10` "Premium" binder; Mystical Tutor overlaps both binders and the top-priority binder must win |
| Invisible Stalker foil (nonfoil ≈ $1, foil ≈ $10) | Finish-specific pricing edge |
| 8 cheap instants (Searing Blaze, Mortify, Fresh Meat, Charge, Afflict, Run Away Together, Nocturnal Raid, Altar's Reap) | Fill a `t:instant` binder sized small (e.g. 2×2, 1 page, single-sided = 4 pockets) to force visible overflow |

## `acceptance_deck.txt`

A one-line decklist to pair with the CSV. Import it, mark the deck
**Assembled**, and one Mystical Tutor copy is reserved — the D13 layer
should take a nonfoil copy (cheapest finish) and leave the foil idle.

## Suggested binder definitions

1. **Premium** — query `usd>=10`, 3×3, 1 page, single-sided (9 pockets),
   top priority. Claims Mystical Tutor (both finishes), Birds of
   Paradise, Narset, Temporal Manipulation.
2. **Instants** — query `t:instant`, 2×2, 1 page, single-sided
   (4 pockets), second priority. Mystical Tutor is already claimed by
   Premium; the 8 cheap instants contend for 4 pockets → overflow badge.

## Caveats

- Scryfall bulk **prices drift daily** and the bulk file's ordering is
  not contractual; the Scryfall IDs are permanent, but if a card ever
  falls out of the first ~5,000 bulk entries it will stop matching the
  quick-import corpus. If rows come up unmatched, re-derive: download the
  head of the current default-cards bulk file and pick replacements (see
  `design/PHASE4_CURRENT_STATUS.md` session notes for the procedure).
- Purchase prices in the CSV are arbitrary; matching and allocation use
  corpus prices, not CSV prices.
