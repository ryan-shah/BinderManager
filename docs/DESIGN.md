# BinderManager — Design Document

**Status:** v1 design locked · **Last updated:** 2026-06-20 · **Stage:** Greenfield (no application code yet)

A Magic: The Gathering collection tool focused on **binder management**. Given an imported
collection and decklists, the user defines binders by rules (type + contents), and the app
auto-fills each binder with cards that are in the collection but **idle** (not reserved by a deck).

---

## 1. Product summary

### 1.1 Core job
Help a player turn **valuable cards that are idle in their collection** into organized, fillable
binders.

- **Primary:** value-driven **trade/sell binders** (e.g. "everything unused worth > $5", or several
  binders split by price band).
- **Secondary:** **showcase binders** filtered by frame / art treatment (full-art, showcase,
  borderless, etc.).

### 1.2 Core loop
`Import collection + decklists → compute idle/eligible pool → define a binder by rules → get a
fillable, physically-followable layout → commit / roll back changes over time.`

### 1.3 Key inputs
- Collection import: **ManaBox (CSV)** in v1; **DelverLens (SQLite)** deferred.
- Decklists: **text/file import** in standard `Nx Name (SET) Collector#` format.
- Card corpus + prices: **Scryfall "Default Cards"** bulk data, downloaded on first run.

---

## 2. Locked design decisions

Each decision below is settled for v1. The **Rationale** notes why; the **Tension** notes the
known cost we accepted.

### D1 — Core job: trade/sell first, showcase second
Value-driven trade/sell binders are the primary product; showcase (frame/art-filtered) binders are
a secondary mode that reuses the same machinery.

- **Rationale:** "in the collection but unused in a deck" *is* the trade-binder mental model; it
  yields the clearest value proposition and success metric. Showcase falls out of the query engine
  for free.

### D2 — Card identity: printing + finish
The canonical identity of a card is **(Scryfall printing, finish)**. `finish ∈ {nonfoil, foil,
etched}`. **Condition** and **language** are *soft attributes* carried on the stack for optional
filtering — **not** part of the identity key.

- **Rationale:** for a trade binder, printing and finish *are* the value (Alpha Bolt ≠ M10 Bolt;
  foil ≠ nonfoil). Making condition/language part of the key would explode card counts and
  complicate dedup, and most ManaBox/DelverLens users don't track condition rigorously.
- **Maps to:** Scryfall per-printing IDs + the `finishes` and `prices` fields.

### D3 — Deck reservation: assembled-by-default, opt-in sharing
A card's "used" (reserved) quantity is computed so it can be excluded from the eligible pool.

- Decks are **assembled by default**: each deck reserves its **full quantity** (effectively *sum
  across decks*), assuming every deck is physically built.
- **Sharing is opt-in** at two levels: a whole deck flagged *shared*, or individual cards flagged
  *shared*. Shared members pool together as **union-max** (a card shared across N decks reserves
  only its single highest count).
- **Maindeck + sideboard** reserve; **maybeboards never reserve**.
- **Printing fidelity:** if a decklist carries printing+finish, honor it. If not, prompt per-import:
  *cheapest-first auto-pull* vs *manually pick versions from the collection*.

- **Rationale:** conservative — errs toward *not* surfacing a card that might be in a built deck.
  Worst case is a missed opportunity, never telling someone to bind a card they need.

### D4 — Pricing: Scryfall snapshot, finish-specific
Prices come from the Scryfall bulk payload (`usd`, `usd_foil`, `usd_etched`, `eur`, …), chosen per
the stack's finish. **Default currency USD** (overridable). **Snapshot-based:** filters evaluate
against the price as of the last data refresh. **Condition is not priced** in v1 (quote NM).

- **Rationale:** one data source, one refresh, fully offline; daily aggregate prices are good enough
  for "is this worth binding." Snapshot avoids binder contents silently shifting mid-session.
- **Tension:** a card that spikes won't move into a binder until the next refresh — acceptable for a
  physical binder reorganized occasionally.

### D5 — Query engine: one unified local engine
A single **local** query engine powers both the search bar and binder content rules. It implements a
**named subset of Scryfall syntax + collection-only extensions**. Structured filter UI (color
checkboxes, **card-type selector**, price slider, set picker, treatment toggles) **compiles to the same internal AST** as the
raw search bar.

- A **binder = saved query + capacity + (group, sort)**.
- **v1 grammar subset:** `c:`/`color:`, `id:`/`identity:`, `usd>`/`usd<`/`usd>=`, `s:`/`set:`/`e:`,
  `t:`/`type:`, `o:`/`oracle:`, `r:`/`rarity:`, `is:foil|etched|fullart|showcase|borderless|promo`,
  `frame:`, `stamp:`.
- **Collection-only extensions (the moat):** `have>=N`, `unused`/`idle` (eligible after deck
  reservation), `finish:`, `lang:`, `condition:`.
- **Deferred:** deep boolean nesting, regex `/.../`, full format-legality, `mana{}` matching.
- **Card type is first-class:** exposed both as a **filter** (`t:`/`type:` — e.g. creature, instant,
  sorcery, artifact, enchantment, planeswalker, land, battle) and as a **grouping/sort axis** (D6),
  everywhere filtering or organization is offered — search, binder contents, and binder layout.

- **Rationale:** Scryfall's API knows every card but **nothing about your collection**, so the
  engine *must* run locally over bulk data joined to inventory. Unifying means every search
  improvement improves binder-building and vice versa. `have:`/`unused:` are what Scryfall
  fundamentally cannot do — the product's differentiator.

### D6 — Multi-binder allocation: consuming, priority-ordered
When multiple binders' queries match the same physical card:

- **Consuming:** one physical copy lands in exactly **one** binder (mirrors physics).
- **Resolution:** an explicit, user-ordered **binder priority list**; the engine walks binders in
  order, each greedily claiming matching stacks from the remaining eligible pool.
- **A (printing+finish) stack is atomic:** all copies move together to the highest-priority matching
  binder — **no intra-stack splitting**. Different *printings* of the same card may land in
  different binders.
- **Overflow:** when matches exceed a binder's capacity, rank by the binder's sort (default price
  desc for trade binders) and surface an explicit **overflow list** ("N matched but didn't fit").
- **Virtual/overlap toggle:** a per-binder mode where a binder is a non-consuming *view* (for
  showcase what-if planning).
- **Within-binder organization:** configurable **group + sort** (two independent axes). Available
  group-by / sort-by axes: **card type**, color/identity, set, rarity, price, name, finish (e.g.
  *group by* card type, *sort by* price desc).

- **Rationale:** consuming-by-default is honest about physics. Priority order is the simplest mental
  model ("fill my premium binder first"). Atomic stacks match how people handle playsets.

### D7 — State model: planned vs committed, with commit/rollback
Each binder has two layers:

- **Planned:** the live query result.
- **Committed:** what is physically sleeved, tracked at exact positions.

Every mutating event (deck add/delete, price refresh, priority reorder, collection import, filter
edit) **stages a diff** (Add / Remove / Move) that the user explicitly **Commits** or **Rolls back**
to the prior committed state. Backed by **snapshot history** (a checkpoint before each change;
retained history is capped/pruned).

- **Insertion** is **append-within-group** by default (drop into the next open pocket of the group),
  with an opt-in **Reflow** action to pay the full re-sort cost deliberately.
- **Pinning:** a committed card can be locked so the engine never proposes moving it.

- **Rationale:** separating planned from committed turns "your binder is wrong, rebuild it" into
  "slot in these 4, pull this 1" — the single design move that makes a rules-based *physical* binder
  usable.
- **Tension:** append-without-reflow lets binders drift out of perfect sort order over time; the
  Reflow nudge ("X% out of order") is the pressure valve.

### D8 — Import: canonical mapping, Replace-or-Append, review queue
- **Canonical key:** Scryfall ID + finish. ManaBox CSV maps via its Scryfall ID column + foil flag.
  DelverLens (deferred) resolves set+collector#+finish → Scryfall ID via the on-device corpus.
- **Per-upload prompt: Replace or Append.** *Replace* swaps the collection snapshot for that
  provenance (external app = source of truth). *Append* merges by canonical identity (same stack
  gains quantity; new identities create stacks). Either path flows through the **D7 commit gate** so
  the user reviews before it's real.
- **Provenance tracked** per card (so dual-app users' snapshots don't stomp each other).
- **Unmatched rows** (typos, tokens, proxies) → **review queue** with manual map / ignore; never
  silently dropped.
- **No free-form in-app collection editing in v1** (push editing back to the source app).

### D9 — Physical model & UI: skeuomorphic flip-through binder
- A binder is an ordered sequence of pockets derived from **{layout rows×cols, user-set page count,
  single/double-sided}**. Capacity = pockets/page × pages; overflow feeds D6's overflow list.
- Committed cards are tracked at **exact (page, side, pocket)** coordinates (required for D7 "Move"
  instructions).
- **Fill order:** page-by-page, **front side then back side** of each sheet (matches physical
  flipping); single-sided is a toggle.
- **Primary surface:** a **skeuomorphic binder UI** the user virtually flips through, rendered to
  look like a real binder. **Secondary:** printable / JSON export.
- Double-faced/split cards: store a per-card "which face shows" preference, default front/most-valuable; low priority.

### D10 — Decklists: text/file import
- v1 ingests decklists via **plain-text paste + file import** in the standard
  `Nx Name (SET) Collector#` format (Arena/MTGO/Moxfield/Archidekt export). The optional `(SET)
  Collector#` suffix is the D3 printing-fidelity signal.
- Each deck is a named entity carrying **format + assembled/shared flags** (D3); sideboards parse
  into a marked section and reserve like maindeck.
- **Unowned cards** (named in a deck but not in the collection) reserve nothing and trigger a prompt:
  **(1)** add them to the collection, **(2)** import the deck but mark them unowned, or **(3)** back
  out to edit the import text. Option 1 makes deck import a collection mutation (rides the D7 gate).
- **Deckbuilder URL/API sync deferred.**

### D11 — Card data: Scryfall Default Cards, downloaded first-run
- Download Scryfall **Default Cards** (one row per printing, English-preferred; carries `finishes` +
  `prices`) on first launch; parse into the indexed local DB.
- **Lazy image cache** from Scryfall's CDN (never bundle images).
- **Manual "Refresh data"** advances the D4 price snapshot; prompt to refresh when data is older than
  ~7 days. **Fully offline after the initial download.**
- **Tension:** first-run ~150 MB download is real friction — wifi-friendly, clear progress, framed
  as one-time.

### D12 — Architecture: Flutter + Dart, drift/SQLite, local-first
- **Flutter + Dart**, single codebase. **Web is a key target** (also Android/iOS/desktop). The
  existing Kotlin/Gradle scaffold is replaced by the Flutter project.
- **Persistence: `drift` (SQLite everywhere).** Native uses bundled `sqlite3`; **web uses
  `sqlite3.wasm` persisted via OPFS** — the performant path that lets the D5 SQL-compile engine run
  unchanged in the browser.
- **Two databases:** a *replaceable* corpus DB (blown away on refresh) and a *durable* user DB
  (collection, decks, binders, positions, history). Opposite lifecycles → kept separate so a corpus
  refresh can't corrupt user state.
- **Query execution: hybrid.** The D5 AST compiles to SQL `WHERE` over indexed columns (fast over
  ~100k printings joined to inventory); an in-memory Dart fallback handles predicates SQL can't
  express, over the already-filtered subset.
- **Commit/rollback (D7): state snapshots** at each checkpoint (binder state is small; snapshots make
  rollback trivially correct). Cap/prune retained history.
- **State management:** Riverpod.
- **Local-first, no backend / no accounts in v1.**
- **Web durability:** request `navigator.storage.persist()` on first run; full-local ~150 MB corpus
  accepted; **JSON export/import** is the v1 durability story. Design the user-data schema *now* with
  **stable IDs + timestamps** so cloud sync can bolt on later without migration pain.
- **DelverLens-on-web:** parse the uploaded `.sqlite` via in-memory `sqlite3.wasm` (file picking
  returns bytes, not paths, on web). If fiddly, CSV/ManaBox import ships first; DelverLens gated to
  native initially.

---

## 3. v1 scope

### In scope
ManaBox CSV import (Replace/Append) · text decklist import + assembled/shared reservation · Default
Cards corpus + snapshot pricing · unified query engine (the D5 subset + `have:`/`unused:`) · single +
multi-binder allocation with priority/overflow · planned-vs-committed with commit/rollback ·
skeuomorphic flip UI with exact positions · JSON export. **Targets: web + Android** from one
codebase.

### Deferred (fast-follow)
DelverLens import (esp. web) · deckbuilder URL sync · cloud sync / multi-device · printable PDF ·
condition-aware pricing · *All Cards* / multi-language · advanced grammar (regex, full legality) ·
in-app collection editing.

---

## 4. Build order (hardest-first, to de-risk early)

1. **Corpus pipeline + drift-on-web (OPFS).** Prove the 150 MB download/parse/query path in a
   browser tab *first* — the biggest unknown; everything sits on it.
2. **Query engine.** AST → SQL hybrid over corpus + a hand-seeded inventory.
3. **ManaBox import + deck reservation.** Produce a real eligible/idle pool.
4. **Allocation + planned/committed + commit/rollback.** The logical core.
5. **Skeuomorphic binder UI + positions + export.** The payoff surface (least *risky*, so it's last).

**First concrete step:** a throwaway spike proving `drift` + `sqlite3.wasm` + OPFS download/query of
a real Scryfall Default Cards bulk file on web. If it performs, the architecture holds.

---

## 5. Open risks / threads to watch

- **Web local-storage durability** — OPFS is evictable and per-origin; clearing site data wipes the
  collection. JSON export/import is the v1 net; cloud sync is the eventual answer. Keep the user
  schema sync-ready.
- **Web technical risk concentrated in build step 1** — 150 MB OPFS-backed SQLite in a browser tab.
  Everything else is well-trodden Flutter.
- **DelverLens-on-web** — in-browser `.sqlite` parsing via wasm is the fiddliest deferred item.
- **Reflow drift (D7)** — append-within-group erodes sort order over time; rely on the
  "X% out of order, reflow?" nudge.
- **Diff-flow trust** — "Move card from page 3 back pocket 5" must be exactly correct and physically
  followable, or trust evaporates. Prototype the diff flow early on real data.
