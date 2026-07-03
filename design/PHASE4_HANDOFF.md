# Phase 4 Handoff

Session handoff document. Written at the end of Phase 3 (2026-07-02) so a
fresh session can begin Phase 4.

## Current State

**PR #5 is MERGED to `main`** (squash `fd1dc4b`, 2026-07-02): all of
Phase 3 — the durable user DB, ManaBox CSV import, decklist import, the
reservation engine, and real `have:`/`unused:` query predicates. 496 tests
pass, `flutter analyze` is info-only (19 pre-existing infos),
`flutter build web` succeeds. PR #6 added a PR-preview deploy workflow
(`pr_preview.yml` / `pr_preview_cleanup.yml`). In-browser validation of the
Phase 3 flows was run 2026-07-02 — check the session/PR notes for its
pass/fail report before building on top.

Run `bd ready` / `bd prime` at session start — beads is the source of truth.

### What Phase 3 delivered (the surfaces Phase 4 builds on)

- **User DB** (`lib/core/database/user_database.dart`, schemaVersion **1**):
  `stacks` (uuid PK, UNIQUE scryfall_id+finish+provenance), `decks`,
  `deck_entries` (FK cascade; `PRAGMA foreign_keys` in `beforeOpen`).
  Provided by `userDatabaseProvider`; the `connect(String name)` factory
  needed no changes (`user.sqlite` native / own OPFS bucket web).
- **Reservation engine** (`lib/core/allocation/reservation.dart`, pure
  Dart): `computeReservations({stacks, decks, entries}) → ReservationSummary`
  with `ownedOf/reservedOf/idleOf`, `ownedIds/idleIds`. Semantics (locked):
  only assembled decks reserve; `reserved = Σ non-shared + max(shared)`;
  maybeboard never; idle clamped ≥ 0; finishes pool.
  `watchReservations(db)` re-emits on any stacks/decks/deck_entries change —
  **this stream is the Phase 4 idle-pool input.**
- **Query integration**: `QueryCompiler(cards, {ReservationSummary?
  collection})` — `have:`/`unused:` compile to scryfall_id id-sets;
  `have>=N` thresholds counts; >500-id sets switch to inline-literal `IN`
  (`_scryfallIdIn`). `QueryEngine(corpus, {UserDatabase? userDb})` resolves
  the snapshot per search, only when the AST uses those fields. **A binder
  rule is just a query string through this same engine (D5).**
- **Imports**: ManaBox CSV (`manabox_parser.dart`, `collection_importer.dart`
  — Replace is an ID-preserving per-provenance snapshot swap, Append a
  quantity upsert) and decklists (`decklist_parser.dart`,
  `deck_repository.dart`, fidelity + unowned prompts). Both notifiers expose
  an `onCommitted` hook wired to `SearchNotifier.refresh()` — extend this
  pattern for binder recomputes.
- **Routes**: `/collection/import`, `/decks/import`, `/decks/:id` inside the
  shell; `_indexFromLocation` prefix-matches. `/binders` is still the
  placeholder `BindersListScreen`.
- **Also landed**: DFC `card_faces` fix (needs a corpus re-import to
  backfill), card-type Any/All filter toggle, `file_selector` + `uuid` deps.

### Loose ends (small, non-blocking)

- Existing local corpora predate schema v2 `borderColor` and the DFC fix —
  **re-download the corpus** in any environment used for testing.
- `ImportDiff.DiffEntry` is qty-only; condition/language-only changes commit
  correctly but don't surface in the preview.
- `have>=N` works in raw queries only; no filter-panel control.
- Finish-level reservation was deferred on purpose: `deck_entries.finish`
  (nullable) exists, so Phase 4's atomic (printing+finish) stacks need no
  migration of deck data. The bridging rule is now locked as **D13** — see
  the adjustments below.
- Search sort is page-local: `SearchNotifier` sorts in memory after
  fetching a page of 100, so e.g. "Price high–low" on a >100-card result
  sorts an arbitrary first page (`BinderManager-552`). Fixed by the
  Phase 4 ORDER BY work below.

### Plan adjustments locked 2026-07-03 (post-Phase-3 review, user-confirmed)

DESIGN.md now carries these as D13 + amendment notes; the decisions:

1. **D13 — finish granularity for allocation:** reservation stays
   printing-level (as built); for per-stack idle quantities, reservations
   consume the **cheapest finish first** (finish-specific D4 price), so
   valuable finishes stay idle for binders. Implement as a layer on
   `ReservationSummary` (per-stack `idleOf(CardIdentity)`), no schema
   change. Correction path: **post-import deck printing editing** in deck
   detail (`BinderManager-wxt`) — decks often run nicer versions on
   purpose; the import-time fidelity prompt already exists.
2. **Engine ORDER BY (Package 0):** `QueryEngine.search()` gains ordering;
   overflow ranking and deterministic allocation need whole-set order, and
   it fixes `BinderManager-552`. The allocator may sort full match sets in
   Dart (it loads them for capacity math anyway); search should use SQL
   ORDER BY.
3. **D7 narrowed to binder state (amendment):** snapshots cover binder
   configs + committed placements ONLY. Imports/deck commits keep their
   Phase 3 review gates and enter D7 as triggering events (the
   `onCommitted` hooks). No double-commit UX; do not retrofit imports.
4. **`unused:` stays deck-idle (D5 amendment):** cards placed in binders
   still match `unused:true` — the allocator consumes from that same pool.
   A placement-status filter (`in:binder` or similar) is Phase 5+.
5. **"Refresh data" (D11) lands in Package 0:** Settings action reusing
   `corpusImportProvider` + a recompute trigger on completion. It is now
   load-bearing: backfills the DFC/borderColor corpus fixes, advances the
   D4 price snapshot, and price refresh is a D7 change event.
6. **JSON export/import of the user DB is a Phase 4 stretch goal** (Agent
   H — snapshot serialization is nearly the same code). It's the v1
   durability net against OPFS eviction; don't let it slip past early
   Phase 5.
7. **Phase 5 note:** the D11 lazy image cache is explicit Phase 5 scope
   (flip-through renders 9–18 pockets per spread; direct CDN loads won't
   hold up).

## Phase 4 Plan (build order step 4: "Allocation + planned/committed + commit/rollback — the logical core")

**Goal:** binders as first-class entities (D5: saved query + capacity +
group/sort), consuming priority-ordered allocation (D6), and the
planned-vs-committed state model with commit/rollback and snapshot history
(D7). UI: binders list (§7), binder editor (§8), change review (§10).
The skeuomorphic flip-through view (§9) is **Phase 5** — but positions
(page/side/pocket) must be modeled and assigned in Phase 4 because D7 diffs
emit exact location instructions ("Move Ragavan → page 3, back, pocket 5").

**Branch:** `phase-4/allocation-and-commit` off `main`.
The Phase 3 execution model worked well — repeat it: orchestrator Package 0
(schema + routes + skeletons + the shared diff/position model + engine
ORDER BY + the "Refresh data" action, one commit, strict file ownership),
two parallel worktree agents, sequential integration.

### Normative requirements (read D5–D7, D9 §1-2, UI_COMPONENTS §7/§8/§10 in full)

- **Binder** = layout (2×2/3×3/4×4) + page count + single/double-sided
  (capacity = pockets/page × pages) + contents query + group-by + sort-by
  (+ direction) + virtual/overlap toggle + priority position.
- **Allocation (D6):** walk binders in user-ordered priority; one physical
  copy lands in exactly one binder; a (printing+finish) **stack is atomic**
  (no intra-stack splitting; different printings may split across binders);
  overflow ranked by the binder's sort, surfaced as an explicit list;
  virtual binders don't consume.
- **State model (D7):** planned = live query result; committed = physically
  sleeved at exact (page, side, pocket). Every mutating event (import, deck
  change, price refresh, priority reorder, rule edit) stages an
  Add/Remove/Move diff → Commit or Roll back. Snapshot history, capped.
  Insertion is append-within-group; **Reflow** is opt-in; **pinned** cards
  are never moved. Fill order: page-by-page, front then back (D9).

### Suggested schema (validate at session start)

`binders`: id (uuid), name, query, priorityIndex, rows, cols, pageCount,
doubleSided, groupBy, sortBy, sortDir, isVirtual, timestamps.
`binder_slots` (committed placements): id, binderId (FK cascade),
scryfallId, finish, quantity, page, side, pocket, isPinned, timestamps.
`snapshots` (D7 history): id, createdAt, trigger label, serialized
committed state (JSON blob is fine — binder state is small; cap/prune).

**Gotcha — migration required:** the user DB shipped at schemaVersion 1.
Adding tables means `schemaVersion => 2` plus an `onUpgrade` that
`m.createTable(...)`s the new tables. Do NOT rely on `createAll`; test the
v1→v2 upgrade path explicitly (open a v1 in-memory DB, migrate, verify).

### Suggested agent split

- **Agent G — allocation core + binder definition:** `binders` table,
  the **D13 per-stack idle layer** on `ReservationSummary`,
  `lib/core/allocation/allocator.dart` (pure Dart: priority walk, atomic
  stacks, capacity/overflow, virtual mode, group+sort ordering, position
  assignment with append-within-group + reflow), binder repository +
  providers, binders list (§7, drag-reorder = change event) + binder editor
  (§8, live match/fit/overflow preview via QueryEngine).
- **Agent H — committed state + change review:** `binder_slots` +
  `snapshots` tables, `lib/core/state/` commit engine (stage diff from
  planned vs committed, Commit applies + checkpoints, Roll back restores,
  pin handling), change-review screen (§10) + the shared sticky
  Commit/Rollback bar (§13), diff row model with location instructions.
  **Stretch:** JSON export/import of the user DB (adjustment 6).
- **Integration:** wire change events (binder edits, reorders, imports via
  the existing `onCommitted` hooks, deck commits, Refresh-data completion)
  into staging; recompute planned via `watchReservations` + QueryEngine;
  card/stack detail placement line (§11) if time allows.
- **Standalone (either agent or orchestrator):** post-import deck printing
  editing in deck detail (`BinderManager-wxt`) — touches only
  `lib/features/decks/` + `deck_repository.dart`.

G and H meet at the diff data model — define it (with the position types)
in Package 0 so both sides compile against it from the start.

### Verify (acceptance)

Import collection + decklist → create two binders with overlapping rules
and set priority → allocation puts each stack in exactly one binder, top
priority wins, overflow listed → commit → edit a rule → review shows
Add/Remove/Move with exact positions → roll back restores → re-commit →
pinned card survives a reflow. Plus the D13 rule: own a printing in foil +
nonfoil, reserve some copies via a deck → the cheapest finish is consumed
and the valuable stack shows idle/allocatable; edit the deck's printing and
watch it correct. And: Refresh data re-downloads the corpus and stages a
binder diff if prices moved. Build gate as always: analyze info-only, all
tests, `flutter build web`.

## Conventions & Gotchas (carried forward + new)

- **Issue tracking:** `bd` only. Session close: work is not done until
  `git push` succeeds.
- **Parallel agents:** orchestrator pre-creates ALL shared artifacts
  (tables, codegen, deps, routes, skeleton screens, shared models) in one
  Package-0 commit; agents get strict disjoint file ownership; agents in
  worktrees must run `flutter pub get` + `dart run build_runner build`
  first (`.g.dart` is **gitignored**; CI runs build_runner itself).
- **Drift:** `@DataClassName` to dodge Flutter name collisions (`StackRow`
  precedent — a `Slots` table would generate `Slot`, check it);
  `textEnum<T>` for enums; uuid v4 + created/updated timestamps (D12);
  `PRAGMA foreign_keys = ON` in `beforeOpen` or cascades no-op.
- **go_router:** literal sub-routes before `:id`; nav index prefix-matches.
- **Tests:** TDD; `ThemeData(splashFactory: NoSplash.splashFactory)`;
  notifier fakes `extends StateNotifier<S> implements N` and MUST mirror
  every public member — adding `onCommitted` to notifiers broke fakes until
  they gained the getter.
- **Filter panel:** `_filterBuilderKey` is only bumped by search-bar
  submits/chip removals; parse-back regexes stay token-anchored. The binder
  editor (§8) reuses these controls — same rules apply there.
- **Compiler:** reuse `_scryfallIdIn` for any new id-set predicate (>500
  ids need the literal-IN path).
- **Windows/PowerShell 5.1:** multi-line or quoted commit messages break
  `-m` argument passing — write to a temp file and `git commit -F <file>`.
- **Debug loop:** onboarding "Quick import — 5,000 cards (debug)";
  `flutter run -d web-server --web-port=<port>`; first load reloads once
  (COI service worker). A fresh port = fresh origin = clean OPFS state.
