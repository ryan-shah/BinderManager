# Phase 3 Handoff

> **STATUS (2026-07-02): Phase 3 is implemented** on
> `phase-3/import-and-reservation` (user DB, ManaBox import, decklist
> import, reservation engine, compiler integration — 496 tests). The plan
> below is kept for reference; remaining work is browser verification and
> the PR to `main`.

Session handoff document. Written at the end of Phase 2 (2026-07-01) so a fresh
session can begin Phase 3 immediately after PR #2 merges to `main`.

## Current State

**PR #2** (`phase-2/query-engine-and-search` → `main`) contains all of Phase 2
plus Phase 2.5, awaiting merge. Head commit: `b03a5e7`. All 300 tests pass,
`flutter analyze` is info-only, `flutter build web` succeeds. All code-review
comments were addressed and replied to on the PR.

CI on `main`: `test.yml` (analyze + test on PRs and main pushes),
`claude-code-review.yml` (automated PR review), `claude.yml` (@claude mentions),
`deploy_github_page.yml` (web deploy to gh-pages on main push).

### What Phase 2 delivered

- **Query engine** (`lib/core/query/`): recursive-descent parser →
  sealed AST (`TextNode`/`FilterNode`/`AndNode`/`OrNode`/`NotNode`) →
  drift `Expression<bool>` compiler → `QueryEngine.search()` facade with
  pagination. Grammar: `c:`, `id:`, `t:`, `s:` (comma lists), `o:`, `r:`,
  `usd` comparisons, `is:`, `frame:`, `stamp:`, `finish:`, `unused:`/`idle:`,
  `have:`, `-` negation, `OR`, quoted strings, parenthesized groups.
  Colorless (`c:C`) and multicolor (`c:M`) are special-cased.
- **Collection search UI** (`lib/features/collection_search/`,
  `lib/shared/widgets/`): query bar + filter rail (desktop) / bottom sheet
  (mobile), Colors/Identity mode toggle, "In collection" + "Idle only"
  switches, applied-filter chips with removal, card grid. Filter panel and
  search bar stay in sync via a key-based rebuild (`_filterBuilderKey`).
- **Phase 2.5**: richer import progress (download % + card count in one
  state), debug quick-import (`runImport(cardLimit: 5000)`, debug-only button
  on onboarding), COOP/COEP service worker (`web/coi_serviceworker.js` +
  deferred bootstrap in `web/index.html`) so drift uses OPFS
  (`opfsLocks`) on static hosts. Corpus schema v2 added `borderColor`
  (additive migration; old local corpora need a re-download to populate it).

### Verified in-browser (Chrome, 2026-07-01)

Fresh visit → SW registers → one reload → `crossOriginIsolated` → drift logs
`WasmStorageImplementation.opfsLocks`. Quick-import stopped at exactly 5,000
cards and aborted the stream download. Verified queries against real data:
`c:M` (612), `c:C t:creature` (183), `is:borderless` (380, was 0 before fix),
`s:khm,neo` (33 = 9+24), `id:R` (1,045 incl. multicolor),
`id:R unused:true have:true (t:instant OR t:sorcery)` (232, no parse error).

### Open issues (beads)

- `BinderManager-aq7` (P2 bug): multi-face cards — Scryfall puts `colors` and
  `image_uris` in `card_faces` for transform/MDFC layouts, so DFCs show as
  colorless and image-less. Fix in `scryfall_parser.dart` `_mapToCompanion`
  (merge face 0 or union colors across faces). Good warm-up task; requires a
  corpus re-import to take effect.

Run `bd ready` / `bd prime` at session start — beads is the source of truth.

## Phase 3 Plan (from the master plan, hardest-first build order)

**Goal:** ManaBox CSV import + user DB, decklist import + reservation engine.
Two parallel agents, then a sequential integration step.

**Branch:** `phase-3/import-and-reservation` off `main` (after PR #2 merges).
Parallel subagents work in worktrees on sub-branches, integrate on the phase
branch, PR to `main` with build gate (analyze clean + tests pass +
`flutter build web`).

### Agent E — ManaBox CSV import + user DB

- `lib/core/database/user_database.dart` — second drift DB (durable user
  data; same platform-conditional connection factory as
  `lib/core/database/connection/`). Web note: opening a second WasmDatabase
  is fine; reuse the existing worker/wasm assets.
- `lib/core/database/tables/collection_tables.dart` — `stacks` table:
  scryfall_id, finish, quantity, condition, language, provenance,
  timestamps. Unique on (scryfall_id, finish, provenance).
- `lib/core/import/manabox_parser.dart` — CSV parse; map Scryfall ID + Foil
  column → canonical `CardIdentity(scryfallId, finish)`
  (`lib/core/models/card_identity.dart` already exists with D2 semantics:
  finish distinguishes identity).
- `lib/features/collection_import/` — file pick/drop, Replace/Append choice,
  parse summary, unmatched-row review queue, diff preview, Commit/Cancel.

### Agent F — Decklist import + reservation engine

- `lib/core/database/tables/deck_tables.dart` — `decks` + `deck_entries`
  (assembled/shared flags, per-card shared override, section
  main/sideboard/maybeboard).
- `lib/core/import/decklist_parser.dart` — parse `Nx Name (SET) Collector#`,
  resolve to scryfall_id via corpus lookup.
- `lib/core/allocation/reservation.dart` — reserved qty per card = sum of
  assembled decks + union-max across shared decks;
  `idle = collection_qty − reserved`, clamped to 0.
- `lib/features/decklist_import/` + `lib/features/decks/` — paste/file
  import, deck metadata, printing-fidelity prompt, unowned-card prompt,
  deck list/detail screens.

### Integration (sequential, after E+F)

Wire real predicates into the compiler. The hooks are already in place:

- `lib/core/query/compiler.dart` `_compileFilter` currently has
  `'unused' => const Constant(false)` and `'have' => const Constant(false)`
  (marked "Phase 3 placeholders" — empty-collection semantics: nothing is
  owned or idle until the user DB exists). Replace with subqueries/joins
  against the user DB (stacks ± reservations). The corpus and user DBs are separate
  files — cross-DB SQL needs either ATTACH or an in-Dart id-set filter
  (`scryfallId IN (...)`); decide during implementation and note the choice.
- UI already emits `have:true` ("In collection") and `unused:true`
  ("Idle only") and round-trips them; chips and widget tests exist.
- Verify: import a real ManaBox CSV, import a decklist, `unused:true usd>5`
  returns only idle cards worth $5+.

## Conventions & Gotchas

- **Issue tracking:** `bd` only (no TodoWrite/markdown TODOs). Create issues
  before coding, `--claim`, close with `--reason`. `bd prime` for the full
  protocol.
- **Session close:** work is not done until `git push` succeeds.
- **Design docs are authoritative:** `design/DESIGN.md` (D1–D12 locked),
  `design/UI_COMPONENTS.md`, `design/STYLE_GUIDE.md` (tokens live in
  `lib/app/theme.dart`).
- **TDD:** tests before/with implementation; widget tests need
  `ThemeData(splashFactory: NoSplash.splashFactory)` on the test MaterialApp
  or InkSparkle shader-decode errors fail them.
- **Codegen:** after touching drift tables run
  `dart run build_runner build --delete-conflicting-outputs`.
- **Debug loop:** use the onboarding "Quick import — 5,000 cards (debug)"
  button instead of the full 150 MB corpus. `flutter run -d web-server
  --web-port=<port>`; first load reloads once (COI service worker) — that is
  expected.
- **Fakes implementing notifiers:** `runImport({int? cardLimit})` — fakes
  must match the signature (see `onboarding_screen_test.dart`).
- **Filter panel sync:** search-bar submits and chip removals bump
  `_filterBuilderKey` to rebuild the panel; the panel's own emissions must
  NOT bump it (infinite rebuild). Preserve this when adding filters.
- **Parse-back regexes** in `query_filter_builder.dart` are token-anchored
  (`(^|\s)prefix`) — keep new prefixes anchored or `s:` will eat `is:`.
