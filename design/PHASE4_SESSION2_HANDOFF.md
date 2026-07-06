# Phase 4 — Mid-Phase Session Handoff

Written 2026-07-05 mid-Phase-4, in prep for a session reset. The Phase 4
*plan* is `PHASE4_HANDOFF.md` — read that first; this doc is only what has
happened since and exactly where to pick up. Beads is the source of truth
(`bd ready` / `bd prime`).

## State of the branch

**Branch:** `phase-4/allocation-and-commit`, pushed to origin. Two commits
on top of main:

1. **`298016f` — Package 0** (orchestrator pre-work, done):
   - User DB **schemaVersion 2**: `binders`, `binder_slots` (data class
     `BinderSlotRow`), `snapshots` (`SnapshotRow`) in
     `lib/core/database/tables/binder_tables.dart`; tested v1→v2 migration
     (`test/core/database/user_database_migration_test.dart`).
   - **Shared models** both agents compile against:
     `lib/core/models/binder_position.dart` (`PageSide`, `BinderPosition`
     with D9 fill-order compareTo + `describe()`, `BinderGeometry` with
     capacity/ordinal math), `lib/core/models/binder_diff.dart`
     (`DiffType`, `ChangeTrigger`, `PlannedPlacement`, `OverflowEntry`,
     `BinderDiffEntry.instruction()`, `StagedDiff`),
     `lib/core/models/ordering.dart` (`SortDirection`, `BinderAxis`).
   - **Engine ORDER BY**: `QueryEngine.search(..., order: QueryOrder?)` —
     SQL-side, applied before pagination, scryfall_id tie-breaker, numeric
     collector-number compare, null price sorts as 0. `SearchNotifier`
     passes it through; `setSort` re-queries. **BinderManager-552 closed.**
   - **D11 Refresh data**: Settings screen action reusing
     `corpusImportProvider`; corpus DB v3 adds `corpus_meta` with
     `imported_at` (`corpusLastUpdatedProvider`, staleness note);
     `lib/app/corpus_refresh_listener.dart` at the app root refreshes
     search on import completion — **integration extends this to stage
     binder diffs**.
   - Routes + skeletons: `/binders/new`, `/binders/:id/edit`
     (`lib/features/binder_editor/`), `/changes`
     (`lib/features/change_review/`).

2. **`05c222f` — D13 printing editor** (done, **BinderManager-wxt
   closed**): `DeckRepository.setEntryPrinting` (sets `printingSpecified`),
   `CorpusDatabase.printingsOfOracle` + `printingsOfOracleProvider`,
   deck-detail rows always show the resolved printing with a swap
   affordance → picker dialog (set/collector, rarity, price, owned
   counts). 551 tests green at this commit.

Gates at `05c222f`: `flutter analyze` info-only (19 pre-existing infos),
551 tests pass, `flutter build web` succeeds (checked at `298016f`).

## Agents G and H — worktrees in flight

Two background worktree agents were launched from `298016f` per the
PHASE4_HANDOFF agent split, **hit a session limit once, and were resumed
2026-07-05 ~9:15am**; at handoff time both were mid-work, uncommitted:

- **Agent G** (`BinderManager-y54`, in_progress) — allocation core +
  binder definition. Worktree:
  `.claude/worktrees/agent-aace026923c7114f5` (branch
  `worktree-agent-aace026923c7114f5`). Last seen: modified
  `lib/core/allocation/reservation.dart` (D13 per-stack idle layer), new
  `lib/core/allocation/allocator.dart`, `lib/core/binders/`, tests
  (`allocator_test.dart`, `stack_idle_test.dart`). Still owed at last
  check: binder providers, binders list §7, binder editor §8.
- **Agent H** (`BinderManager-2po`, in_progress) — commit engine + change
  review. Worktree: `.claude/worktrees/agent-a032ec2acbaf02daa` (branch
  `worktree-agent-a032ec2acbaf02daa`). Last seen: new `lib/core/state/`,
  `lib/shared/providers/change_staging_provider.dart`,
  `lib/shared/widgets/commit_rollback_bar.dart`, modified
  `change_review_screen.dart`, tests under `test/core/state/`,
  `test/features/change_review/`, `test/shared/widgets/`.

**A fresh session cannot message those agents** (agent ids are
session-scoped). Recovery procedure:

1. `git -C .claude/worktrees/agent-<id> status --short` and `git log` on
   both worktrees. Agents were instructed to COMMIT when done (prefixes
   "Phase 4 Agent G:" / "Phase 4 Agent H:") and never push.
2. If a worktree has committed, green work → merge it into
   `phase-4/allocation-and-commit` (G first, then H; they own disjoint
   files, so conflicts should be none/trivial).
3. If work is uncommitted/incomplete → adopt the worktree diff, finish it
   against the agent brief (the full briefs, incl. **strict file
   ownership**, normative allocator/commit-engine rules, and definition
   of done, live in the beads issues `BinderManager-y54` /
   `BinderManager-2po` and in PHASE4_HANDOFF "Suggested agent split").
   Run `flutter pub get` + `dart run build_runner build
   --delete-conflicting-outputs` inside a worktree before judging compile
   state — `.g.dart` is gitignored.
4. Worktree agents know nothing of `05c222f` (they branched at
   `298016f`) — that's fine; neither touches deck files.

## Then: integration (`BinderManager-2xd`, blocked on y54 + 2po)

After both merge, in the main tree:

- Wire change events into H's staging: binder create/edit/delete +
  priority reorder (G's repository), collection-import and deck-commit
  `onCommitted` hooks (`collection_import_provider.dart`,
  `deck_providers.dart` — currently they only call
  `SearchNotifier.refresh()`), Refresh-data completion
  (`corpus_refresh_listener.dart` has the marked extension point), and
  deck edits incl. the new `setEntryPrinting`.
- Recompute planned on staging: `watchReservations(db)` + per-binder
  QueryEngine match sets + G's D13 idle layer + G's allocator → planned
  placements → H's `stage(trigger, planned, overflow)`.
- Surface the pending diff: route to `/changes`, mount H's
  commit/rollback bar where a diff is staged (§13), binders-list pending
  banner (§7).
- Card/stack detail placement line (§11) only if time allows.
- **Acceptance pass** — run the full "Verify" list in PHASE4_HANDOFF
  (two overlapping binders, priority, overflow, commit, rule edit,
  rollback, re-commit, pinned-survives-reflow, D13 cheapest-finish +
  printing-edit correction, Refresh-data staging a price diff). In-browser
  check via `flutter run -d web-server --web-port=<fresh port>` (fresh
  port = clean OPFS; first load reloads once for the COI worker).
- Stretch if H didn't get to it: JSON export/import of the user DB — do
  not let it slip past early Phase 5 (durability net).

## Beads snapshot (2026-07-05)

- Closed this session: `BinderManager-a6q` (Package 0),
  `BinderManager-552` (page-local sort), `BinderManager-wxt` (printing
  editor), `BinderManager-zd2` (stale Phase 0).
- In progress: `BinderManager-y54` (Agent G), `BinderManager-2po`
  (Agent H).
- Blocked: `BinderManager-2xd` (integration, on y54+2po).
- Untouched known bugs: `BinderManager-apy` (multi-tab OPFS wedge, P2),
  `BinderManager-b2r` (reserve summary overstates, P3),
  `BinderManager-bqq` (unowned list loses sections, P3).

## Gotchas re-learned this session

- Background agents die silently on plan session limits; their worktree
  state is the only artifact. Check worktrees before assuming loss.
- `bd update --claim` did not set in_progress on then-blocked issues; set
  `--status=in_progress` explicitly after unblocking.
- All PHASE4_HANDOFF "Conventions & Gotchas" still apply (build_runner in
  worktrees, `git commit -F` on PowerShell 5.1, fakes must mirror every
  public member — `FakeDeckRepository` gained `setEntryPrinting` this
  session, notifier fakes gained nothing).
