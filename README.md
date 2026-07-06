# BinderManager

A Magic: The Gathering collection tool focused on **binder management**. Given an imported collection and decklists, define binders by rules and the app auto-fills each binder with idle cards — cards you own but aren't using in any deck.

## Current Status

**Phase 4 in progress — allocation engine + staged commit/rollback** (branch `phase-4/allocation-and-commit`; core engines, binder UI, and change staging are integrated and green, in-browser acceptance pass pending). **Phases 1–3 are merged to `main`.**

### What's implemented

**Phase 1–2 — corpus + search**
- **Corpus data pipeline:** Scryfall Default Cards bulk download with streaming parse, batch insert into drift/SQLite database. Platform-conditional connection factory (native SQLite + sqlite3.wasm/OPFS for web). Debug quick-import mode (~5,000 cards).
- **App shell:** Desktop sidebar + top bar with data freshness indicator, mobile bottom navigation, responsive breakpoint at 808px, warm-neutral design-token theme.
- **Onboarding + router:** First-run corpus download flow, GoRouter with onboarding redirect.
- **Query engine:** Recursive descent parser for a Scryfall-subset grammar (`c:`, `id:`, `t:`, `s:`, `o:`, `r:`, `usd`, `is:`, `frame:`, `stamp:`, `finish:`, `have:`, `unused:`, `-` negation, `OR`, parenthesized groups, quoted strings) compiled to drift SQL, with pagination and SQL-side ORDER BY.
- **Collection search screen:** Filter rail/bottom sheet, query bar, applied filter chips, sort control, responsive card grid.

**Phase 3 — user collection + decks**
- **User database:** Owned stacks (printing + finish + quantity), decks, deck entries — drift/SQLite alongside the corpus DB, with JSON-safe codecs.
- **ManaBox CSV import:** Streaming parse, matched/unmatched review with reasons, append/replace modes, map-unmatched dialog.
- **Decklist import:** Plain-text decklist parsing with printing resolution prompts, main/sideboard/maybeboard sections.
- **Reservation engine:** Assembled decks reserve owned copies; `have:`/`unused:` query terms filter the collection by ownership and idle status.
- **Deck screens:** Deck list, deck detail with assembled/shared flags, per-entry shared toggles, reserve summary, post-import printing editor (D13 correction path).

**Phase 4 — binders + allocation + staged changes** (this branch)
- **Binder model:** `binders`, `binder_slots`, `snapshots` tables (user DB schema v2); binder geometry (rows × cols × pages, single/double-sided) with D9 fill-order position math.
- **Allocation core:** D6 priority walk — each idle stack placed in exactly one binder, top-priority binder wins, overflow tracked per binder; D13 per-stack idle layer distributes reservations to the **cheapest finish** first using corpus prices; virtual binders act as non-consuming views.
- **Change staging (D7):** Every mutating event (collection import, deck commit/edit, binder rule edit, priority reorder, corpus price refresh) recomputes planned placements and stages an Add/Remove/Move diff against committed state. Commit applies the diff and checkpoints a snapshot (capped history) in one transaction; rollback restores the last committed state including binder definitions.
- **Binder UI:** Binders list with drag-to-reorder priority, fill gauges, and overflow badges; binder editor with debounced live match/fit/overflow preview; change review screen with commit/rollback bar; app-wide pending-changes banner.
- **Settings:** Refresh data (corpus re-download) with staleness indicator, wired into diff staging.
- **CI/CD:** GitHub Actions — Flutter web deploy to GitHub Pages, PR preview deploys, Claude Code Review on PRs, Claude Code on @mentions.

### What's next
- Phase 4 close-out: in-browser acceptance pass (see `design/PHASE4_HANDOFF.md` "Verify" and `design/PHASE4_CURRENT_STATUS.md` for live status), then merge to `main`.
- **Phase 5:** JSON export/import of the user DB (durability net), card/stack detail placement line, polish, bug backlog (tracked in beads).

## Tech Stack
- **Flutter + Dart** (single codebase, web + Android)
- **drift** (SQLite ORM — native + sqlite3.wasm/OPFS on web)
- **Riverpod** (state management)
- **GoRouter** (declarative routing)

## Build & Run

```bash
flutter pub get
dart run build_runner build    # generate drift database code
dart run tool/setup_web.dart   # download sqlite3.wasm + compile drift worker (web only)
flutter run -d chrome          # web
flutter run -d android         # Android emulator/device
flutter test --timeout 30s     # run tests (see CLAUDE.md for test-run gotchas)
```

For manual testing, `examples/` has a ready-made collection CSV + decklist
that match the debug quick-import corpus — see [examples/README.md](examples/README.md).

## Project Structure

```
lib/
  main.dart                    # Entry point (ProviderScope + MaterialApp.router)
  app/
    router.dart                # GoRouter with onboarding redirect + pending-changes scope
    corpus_refresh_listener.dart # Refresh-data completion hook (search refresh + diff staging)
    theme.dart                 # Design tokens from STYLE_GUIDE.md
    responsive.dart            # Desktop/mobile breakpoint (808px)
  core/
    database/
      connection/              # Platform-conditional DB connection (native/web)
      tables/                  # Drift tables (corpus, collection, deck, binder)
      corpus_database.dart     # Scryfall card corpus DB
      user_database.dart       # User DB (stacks, decks, binders, slots, snapshots)
    import/                    # Scryfall bulk, ManaBox CSV, decklist parsers
    query/                     # Parser → AST → drift SQL compiler → QueryEngine
    decks/                     # DeckRepository
    binders/                   # BinderRepository
    allocation/                # D6 allocator, D13 stack-idle reservation, AllocationPlanner
    state/                     # D7 diff engine, ChangeStagingService, snapshot codec
    models/                    # CardIdentity, BinderPosition/Geometry, BinderDiff, ordering
  features/
    shell/ onboarding/         # App shell, first-run corpus download
    collection_search/         # Search screen with filter rail/sheet
    collection_import/         # ManaBox CSV import + review
    decks/ decklist_import/    # Deck list/detail, decklist import
    binders_list/              # Priority-ordered binder rows, fill gauges, overflow
    binder_editor/             # Binder form with live match/fit/overflow preview
    change_review/             # Staged diff review + commit/rollback
    settings/                  # Refresh data, storage info
  shared/
    widgets/                   # ManaPip, CardTile, QueryFilterBuilder, CommitRollbackBar, PendingChangesBanner, …
    providers/                 # Riverpod providers (corpus, user DB, search, decks, binders, staging)
design/
  DESIGN.md                    # Locked design decisions (D1-D13)
  UI_COMPONENTS.md             # Screen specs (13 screens + reusable components)
  STYLE_GUIDE.md               # Visual design tokens
  PHASE*_HANDOFF.md            # Per-phase plans and handoffs
  PHASE4_CURRENT_STATUS.md     # Living status doc for the active phase
examples/                      # Acceptance-test collection CSV + decklist fixtures
Wireframes/                    # Mid-fi wireframes (exported HTML)
```

## Design Documents

- **[DESIGN.md](design/DESIGN.md)** — Product design with locked decisions (D1–D13) covering card identity, pricing, query engine, allocation, state model, and architecture
- **[UI_COMPONENTS.md](design/UI_COMPONENTS.md)** — Detailed specs for all 13 screens plus reusable component library
- **[STYLE_GUIDE.md](design/STYLE_GUIDE.md)** — Comprehensive visual tokens extracted from wireframes

## Issue Tracking

This project uses [beads](https://github.com/gastownhall/beads) (`bd`) for issue tracking; see `CLAUDE.md` for agent workflow rules.
