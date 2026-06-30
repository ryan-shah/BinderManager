# BinderManager — UI Component & Screen Specs (Wireframe Input)

**Status:** v1 · **Last updated:** 2026-06-20 · Companion to [`DESIGN.md`](./DESIGN.md)

These are prompt-ready descriptions for generating wireframes. Each surface lists **Purpose**,
**Traces to** (the DESIGN.md decision it implements), **Key elements**, a **`[DESKTOP]`** and
**`[MOBILE]`** layout block, **States**, and **Primary interactions**. Target: Flutter, web + Android
from one codebase (D12).

**Visual tone:** clean, data-dense but uncluttered; MTG-aware (color pips = WUBRG, finish indicators
for foil/etched). The binder view is deliberately **skeuomorphic** (looks like a real binder, D9);
everything else is flat/modern utility UI.

---

## 0. App shell & global navigation

**Purpose:** consistent frame, navigation, and global status (data freshness).
**Traces to:** D11 (staleness), D12 (platform).

**Key elements:** app title/logo · global search field (opens Collection Search, D5) · data-refresh
control with **"last updated" timestamp** + staleness badge (D11) · settings entry · primary nav
destinations: **Binders, Collection, Decks, Settings**.

`[DESKTOP]` Persistent **left sidebar** (nav destinations + binder shortcuts), top bar with global
search + refresh/settings on the right, main content pane fills the rest. Sidebar collapsible to
icons.

`[MOBILE]` **Bottom nav bar** (Binders · Collection · Decks · Settings, 4 icons). Top app bar shows
screen title + contextual actions; global search is an icon that expands to a full-width field.

**States:** data fresh (subtle timestamp) vs **stale > 7 days** (amber "Refresh recommended" banner,
D11) · refresh in progress (progress in the refresh control).

---

## 1. First-run onboarding & corpus download

**Purpose:** one-time setup — download the ~150 MB Scryfall Default Cards corpus, request persistent
storage on web.
**Traces to:** D11, D12 (web OPFS persistence).

**Key elements:** brief value prop (1–2 lines) · **"Download card database (~150 MB, one time)"**
primary action with size + "Wi-Fi recommended" note · **progress bar** (downloading → parsing →
indexing, with %) · **web-only:** "Keep data on this device?" persistent-storage consent step ·
success → continue to Home.

`[DESKTOP]` Centered single-column card on a neutral background, max-width ~560px. Stepper feel:
Welcome → Download → (web) Storage permission → Done.

`[MOBILE]` Full-screen single column, same steps stacked; primary button pinned near bottom.

**States:** initial · downloading (progress + cancel) · parsing/indexing (indeterminate-then-%) ·
**error/retry** (network failed, resumable) · web storage-denied (warn: data may be evicted, offer
retry / continue anyway) · complete.

---

## 2. Home / Dashboard

**Purpose:** at-a-glance entry point; surface the headline insight ("idle value") and route to
binders.
**Traces to:** D1 (idle value is the core insight), D7.

**Key elements:** **headline stat — total idle/unused value** (sum of eligible pool, D5 `unused:`) ·
secondary stats: total collection value, # cards, # binders, # decks · **binder cards** (one per
binder: name, type/price-band label, fill gauge e.g. 142/180 pockets, overflow count if any) ·
**"+ New binder"** · pending-changes indicator if an uncommitted diff exists (D7) · data-freshness
timestamp.

`[DESKTOP]` Top row of stat tiles; below, a **responsive grid of binder cards** (3–4 across); right
rail (optional) for "needs attention" (uncommitted diffs, unmatched-import review queue, stale data).

`[MOBILE]` Stat tiles in a 2-wide scrollable row at top; **vertical list of binder cards** below; FAB
"+ New binder". Attention items as dismissible banners at top.

**States:** empty (no import yet → big "Import your collection to begin" CTA) · normal · has
pending changes (banner: "You have unreviewed changes → Review").

---

## 3. Collection import (ManaBox CSV)

**Purpose:** bring a collection in; choose Replace vs Append; review unmatched rows; gate behind
commit.
**Traces to:** D8 (Replace/Append, provenance, review queue, commit gate), D12 (file = bytes on web).

**Key elements:** **file picker / drop zone** ("Drop ManaBox CSV or browse") · detected source +
row count · **Replace ⟷ Append choice** (segmented control, with a one-line explanation of each, D8) ·
parse summary ("1,240 rows · 1,228 matched · 12 unmatched") · **unmatched review queue** (list of
rows that didn't resolve, each with raw text + "map to printing" search + "ignore as token/proxy") ·
**diff preview** (what Commit will change) → **Commit / Cancel** (D7 gate).

`[DESKTOP]` Two-pane: left = upload + options + summary; right = **review queue table** (raw row,
suggested match, action). Sticky bottom action bar: "Review changes → Commit".

`[MOBILE]` Single column wizard: Upload → choose Replace/Append → Summary → Review unmatched (full
list, tap a row to map) → Commit. Action bar pinned bottom.

**States:** empty · parsing · parsed-clean (no unmatched) · parsed-with-unmatched (queue badge) ·
**Replace warning** ("This replaces your ManaBox collection: 1,240 cards, was 3,500 — review before
committing", D8) · committing · done.

---

## 4. Decklist import

**Purpose:** import a decklist as text/file; set deck metadata; resolve unowned cards.
**Traces to:** D3 (assembled/shared, printing-fidelity prompt), D10 (text format, unowned prompt).

**Key elements:** **large paste field** (placeholder shows `4 Lightning Bolt (M10) 146`) + "or import
file" · deck **name** + **format** fields · **Assembled / Shared** toggle for the deck (D3) ·
**parse preview** (parsed card rows; main vs sideboard sections; per-card **"shared"** toggle) ·
**printing-fidelity prompt** when the list lacks printings: *Cheapest-first* vs *Pick versions from
collection* (D3) · **unowned-card prompt** (modal): *(1) Add to collection · (2) Import & mark
unowned · (3) Edit text* (D10) · Commit (D7).

`[DESKTOP]` Two-pane: left = paste box + deck metadata; right = **live parse preview** (sectioned
list, unowned rows flagged, shared toggles). Prompts appear as inline banners/modals.

`[MOBILE]` Single column: paste → metadata → preview (scroll) → prompts as bottom sheets → Commit.

**States:** empty · parsing · parsed (all owned) · parsed-with-unowned (prompt) · missing-printings
(fidelity prompt) · committing · done.

---

## 5. Decks — list & detail

**Purpose:** manage decks and see how they reserve cards from the collection.
**Traces to:** D3 (reservation, assembled/shared), D10.

**Key elements (list):** deck rows (name, format, card count, **Assembled/Shared** badge, "X unowned"
badge) · "+ Import deck" · search/filter.
**Key elements (detail):** deck header (name, format, flags, re-import/update button) · **card list**
(main + sideboard, each with qty, printing if fidelity-honored, **reserved** indicator, per-card
shared toggle) · **"wants you don't own"** section (D10) · "Cards this deck reserves from your
collection" summary.

`[DESKTOP]` List = left nav column of decks + main detail pane (master-detail). Detail uses a card
table.
`[MOBILE]` List screen → tap → full detail screen; sideboard and unowned as collapsible sections.

**States:** no decks (CTA) · deck with all cards owned · deck with unowned cards (flagged) · shared
deck (reservation note: "shares cards via union-max").

---

## 6. Collection search / browser

**Purpose:** the unified query surface — search the collection with the Scryfall subset + collection
extensions; structured filters compile to the same query.
**Traces to:** D5 (unified engine, subset + `have:`/`unused:`), D2 (printing+finish), D4 (price).

**Key elements:** **raw query bar** (Scryfall-subset syntax, with `unused:`/`have:` hints) ·
**toggle to a structured filter panel**: color/identity (WUBRG pips), **card-type multi-select**
(creature, instant, sorcery, artifact, enchantment, planeswalker, land, battle…), **price-band
slider** (D4), set picker (multi, include/exclude), rarity, **treatment toggles**
(`is:foil/etched/fullart/showcase/borderless/promo`, D5), oracle text · **"Idle only" toggle**
(`unused:`) · **"Group by" control for results** (card type, color, set, rarity, price) ·
**results grid** of card stacks (image, qty owned badge, **finish indicator**, price, **reserved vs
idle** badge, which binder it's in) · result count + applied-filter chips · sort control.

`[DESKTOP]` Left **filter rail** (collapsible), main = query bar on top + dense **card grid** (5–7
across). Clicking a chip edits the query. Filter rail and raw query stay in sync (editing one updates
the other).
`[MOBILE]` Query bar on top; **"Filters" button** opens a full-height bottom sheet of structured
controls; results as a 2–3 wide grid; applied-filter chips scroll horizontally under the bar.

**States:** empty query (show all owned) · no results · invalid query (inline parse error with
caret) · loading.

---

## 7. Binders — list

**Purpose:** see all binders, set their **priority order** (drives allocation), create new ones.
**Traces to:** D6 (consuming allocation by explicit priority order), D9 (capacity/fill).

**Key elements:** **priority-ordered, drag-reorderable list** of binders (order = allocation
priority, top wins) · each row: name, type (layout + page count), content summary (e.g. "$5–20,
non-foil"), **fill gauge** (used/total pockets), **overflow badge** ("+23 didn't fit"), virtual/
overlap badge if set · "+ New binder" · note that reordering is a change event → diff/commit (D7).

`[DESKTOP]` Single ordered column (drag handles) with rich rows; "+ New binder" top-right. Optional
right preview of the selected binder.
`[MOBILE]` Vertical reorderable list (long-press drag); FAB "+ New binder".

**States:** no binders (CTA) · normal · reorder-in-progress · post-reorder pending diff banner.

---

## 8. Binder editor / rule definition

**Purpose:** define a binder = **type + contents (query) + organization + capacity** (D5/D6/D9).
**Traces to:** D5, D6, D9.

**Key elements:**
- **Type:** pocket layout selector (2×2 / 3×3 / 4×4), **page count** stepper, single/double-sided
  toggle (D9). Live capacity readout.
- **Contents:** the same query/filter controls as §6 (structured + raw, in sync) — colors, **card
  type**, **price band**, sets include/exclude, treatments, rarity, idle-only.
- **Organization:** **Group by** dropdown + **Sort by** dropdown (two independent axes, D6; axis
  options include **card type**, color, set, rarity, price, name, finish) + direction.
- **Mode:** **Virtual / overlap-allowed** toggle (showcase what-if vs consuming, D6).
- **Live preview:** "matches N cards · fits M · **overflow K**" (D6) updating as rules change.
- Save → recompute planned → diff/commit (D7).

`[DESKTOP]` Two-pane: left = stacked rule sections (Type, Contents, Organization, Mode); right =
**live preview** (mini binder-grid preview + match/fit/overflow counters). Sticky "Save" bar.
`[MOBILE]` Single-column accordion of the rule sections; sticky preview summary chip ("142 fit · 23
overflow") at bottom that expands to the mini preview; Save pinned.

**States:** new binder (defaults) · editing existing · over-capacity (overflow highlighted) ·
under-fill (gaps note) · invalid query.

---

## 9. Binder view — skeuomorphic flip-through  ⟵ hero surface

**Purpose:** the payoff — view a binder as a real, flippable binder; act on planned vs committed
state.
**Traces to:** D9 (skeuomorphic, exact page/side/pocket), D7 (planned vs committed, pinning), D6
(overflow).

**Key elements:** realistic **binder spread** with pockets in the binder's grid (2×2/3×3/4×4), each
**pocket** holding a card image (or empty pocket art) · **page-flip** controls + page indicator
("page 3 of 20", front/back if double-sided) · **group section labels/dividers reflecting the
binder's group-by** (e.g. card-type sections: Creatures, Instants, Lands…) · per-card **pin** affordance · **planned vs committed**
visual distinction (e.g. ghosted "to add" cards, marked "to pull/move") · **"Review changes"** entry
if a diff is pending (D7) · **overflow drawer** ("23 didn't fit", D6) · binder switcher · edit-rules
shortcut (→ §8).

`[DESKTOP]` Large centered binder spread showing **two facing pages** (left+right), realistic rings/
spine; arrows or drag to flip; thumbnail page-strip along the bottom for jump navigation; right rail
for binder info + pending-changes + overflow.
`[MOBILE]` **One page at a time**, full-width; **swipe to flip** with page-curl animation; bottom
sheet for page jump / overflow / review-changes; tap a pocket → card detail.

**States:** committed (stable) · **has pending diff** (Add ghosts / Remove+Move markers visible,
"Review →") · empty binder · reflow-suggested banner ("18% out of order — Reflow?", D7) · pinned
cards shown locked.

---

## 10. Change review — diff & commit/rollback

**Purpose:** the universal gate — review the staged diff from any change event and Commit or Roll
back.
**Traces to:** D7 (planned vs committed, snapshot history), D6 (overflow), D8/D10 (import/deck
changes route here).

**Key elements:** what triggered it (deck added / price refresh / reorder / import / filter edit) ·
**diff list grouped by binder**, rows typed **Add / Remove / Move**, each with **exact physical
location instruction** ("Move *Ragavan* → page 3, back, pocket 5"; "Pull *Bolt* from page 2, front,
pocket 1") · **overflow changes** · summary counts · **Commit** (apply, planned=committed) /
**Roll back** (discard to prior snapshot) · optional per-row accept/skip.

`[DESKTOP]` Full-width list with columns (Type · Card · From → To location · Binder); filter by
binder/type; sticky footer "Commit all / Roll back". Optional split: diff list + mini binder preview
highlighting the moves.
`[MOBILE]` Grouped list (collapsible per binder); each row tappable for detail; bottom action bar
"Commit / Roll back".

**States:** no pending changes (this screen is empty/unreachable) · pending diff · partial-accept (if
supported) · committing · rolled-back confirmation.

---

## 11. Card / stack detail

**Purpose:** drill into a single (printing+finish) stack — value, ownership, reservation, placement.
**Traces to:** D2 (printing+finish identity, soft attrs), D3 (reservation), D4 (price), D6 (which
binder).

**Key elements:** large card image · name, set, collector #, **finish** (nonfoil/foil/etched),
rarity · **price** (finish-specific, currency, as-of timestamp, D4) · **quantity owned** ·
**condition/language** soft attributes · **reservation panel** ("reserved by: Mono-Red (4)") ·
**placement** ("in binder: Premium, page 3 back pocket 5") or "idle / unassigned" · other printings
of the same card you own (jump links).

`[DESKTOP]` Modal or right-side panel: image left, details right.
`[MOBILE]` Full-screen sheet: image top, scrollable details below.

**States:** idle (eligible) · reserved (in deck) · placed (in a binder) · pinned.

---

## 12. Settings

**Purpose:** preferences, data refresh, and the JSON durability story.
**Traces to:** D4 (currency), D11 (refresh/staleness), D12 (JSON export/import, web storage).

**Key elements:** **currency** selector (D4) · **default page layout / single-double-sided** default
(D9) · **Refresh card data** action + last-updated timestamp + staleness state (D11) · **Export
collection (JSON)** / **Import collection (JSON)** (D12 durability) · **web-only:** storage-persistence
status + "request persistent storage" · provenance/source management (which import sources are
active, D8) · about/version.

`[DESKTOP]` Single scrolling column of grouped setting sections (max-width), or left sub-nav of
sections + right detail.
`[MOBILE]` Standard grouped settings list.

**States:** normal · refresh in progress · export/import in progress · web storage not-persisted
(warning).

---

## 13. Reusable components (cross-screen)

These appear in multiple surfaces; describe once, reuse.

- **Card/stack tile** — image, **qty badge**, **finish indicator** (foil/etched), price chip,
  status badge (**idle / reserved / placed / pinned**). Compact (grid) and row variants. (D2/D3/D4/D6)
- **Pocket cell** — a single binder pocket: card image or empty-pocket art; states normal / pinned /
  **to-add (ghost)** / **to-remove** / **to-move**; tap → card detail. (D9/D7)
- **Query/filter builder** — color (WUBRG pip toggles), **card-type multi-select**
  (creature/instant/sorcery/artifact/enchantment/planeswalker/land/battle…), **price-band slider**,
  set multi-picker (include/exclude), rarity, **treatment toggles**, oracle text, idle-only; kept in
  sync with a **raw query bar**; emits the shared query AST. (D5)
- **Applied-filter chips** — removable chips reflecting the active query; editable. (D5)
- **Diff row** — Add/Remove/Move with card + **exact (page, side, pocket)** from→to location. (D7)
- **Commit/Rollback action bar** — sticky; appears wherever a change is staged. (D7)
- **Priority-orderable list item** — drag handle + rich content (used for binder priority). (D6)
- **Group/sort control** — paired **group-by** + **sort-by** selectors sharing one axis list (**card
  type**, color/identity, set, rarity, price, name, finish) + direction; used by binder organization
  and optional search-result grouping. (D5/D6)
- **Fill / capacity gauge** — used/total pockets + overflow count. (D6/D9)
- **Data-freshness banner** — last-updated timestamp + stale (>7d) refresh prompt. (D11)
- **Page-flip control** — prev/next + page indicator (front/back aware); animated curl on mobile.
  (D9)

---

## 14. Screen inventory (build/wireframe checklist)

| # | Screen | Hero? | Traces to |
|---|--------|-------|-----------|
| 0 | App shell & nav | — | D11, D12 |
| 1 | First-run / corpus download | — | D11, D12 |
| 2 | Home / dashboard | — | D1, D7 |
| 3 | Collection import (CSV) | — | D8 |
| 4 | Decklist import | — | D3, D10 |
| 5 | Decks list & detail | — | D3, D10 |
| 6 | Collection search / browser | — | D5, D2, D4 |
| 7 | Binders list (priority) | — | D6 |
| 8 | Binder editor / rules | — | D5, D6, D9 |
| 9 | **Binder view (flip-through)** | ★ | D9, D7, D6 |
| 10 | Change review (diff/commit) | — | D7 |
| 11 | Card / stack detail | — | D2, D3, D4, D6 |
| 12 | Settings | — | D4, D11, D12 |

**Suggested wireframe order:** start with **#9 (binder view)** and **#8 (binder editor)** — the hero
loop that proves the product feel — then **#6 (search/filters)** since it's reused by #8, then the
import/onboarding flow (#1–#4), then #10 (diff) and the supporting screens.
