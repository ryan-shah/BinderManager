# Phase 4 — Current Status

> **Living document.** Update this file as work progresses so any session
> (including one killed by a timeout or plan limit) can resume from here.
> Beads (`bd prime` / `bd ready`) is still the source of truth for issues;
> this doc is the narrative "where exactly were we" layer on top.
>
> Last updated: 2026-07-05 (session 3 — post-merge integration recovery).

## TL;DR

Both Phase 4 worktree agents (G: allocation core, H: commit engine) are
**merged** into `phase-4/allocation-and-commit` (`6f74842`, `64f4902`).
The integration work (`BinderManager-2xd`) is **code-complete and sitting
uncommitted in the main working tree**. Session 2 timed out while fixing
failing tests; some widget tests hang, so `flutter test` must be run with
`--timeout` (e.g. `flutter test --timeout 30s`) to make them fail instead
of wedging the suite.

## Branch state

`phase-4/allocation-and-commit`, 4 commits ahead of the last push point:

- `4f10963` / `6f74842` — Agent G merge: `lib/core/allocation/`
  (allocator, reservation D13 stack-idle), `lib/core/binders/`
  (BinderRepository), tests.
- `9fbc8f5` / `64f4902` — Agent H merge: `lib/core/state/`
  (ChangeStagingService/committed state), `change_staging_provider.dart`,
  `commit_rollback_bar.dart`, change review screen, tests.

**Uncommitted integration work** (all of `BinderManager-2xd`):

- `lib/core/allocation/allocation_planner.dart` — loads live DB state,
  computes D13 stack-idle, resolves match sets via QueryEngine
  (`(query) unused:true`), runs D6 priority walk. Supports `BinderDraft`
  for the editor's live preview.
- `lib/shared/providers/binder_providers.dart` — binder repo/list/slots
  providers, `allocationProvider`, and `BinderChangeStager` which turns a
  `ChangeTrigger` into a staged D7 diff (virtual binders excluded).
- Change events wired everywhere:
  - `corpus_refresh_listener.dart` → `ChangeTrigger.priceRefresh`
  - `collection_import_provider.dart` → `collectionImport`
  - `deck_providers.dart` (deck import) + `deck_detail_screen.dart`
    (assembled/shared toggles, entry shared, printing swap, delete) →
    `deckChange`
  - `binders_list_screen.dart` (drag reorder) → `priorityReorder`
  - `binder_editor_screen.dart` (save/delete) → `ruleEdit`
- `lib/shared/widgets/pending_changes_banner.dart` — `PendingChangesScope`
  mounted in the router's ShellRoute; slim amber banner on every shell
  screen when a diff is staged, hidden on `/changes`.
- `binders_list_screen.dart` — full §7 implementation (fill gauges,
  overflow badges, reorder, pending banner via scope).
- `binder_editor_screen.dart` — full §8 implementation (live match/fit/
  overflow preview via `AllocationPlanner.plan(draft: …)`).
- Tests: `allocation_planner_test.dart`, `binder_providers_test.dart`,
  `pending_changes_banner_test.dart`, `binders_list_screen_test.dart`,
  `binder_editor_screen_test.dart`; helpers `fake_binder_change_stager.dart`,
  `corpus_seed.dart`.
- `test/scratch_probe_test.dart` — **debug artifact from the hang
  investigation; delete before committing.**

## Where session 2 died

Combining agent changes + integration was done; the session was fixing
failing tests when it hit the timeout. Known facts:

- Some widget tests **hang** (pump/settle never settles — spinner or
  stream keeps scheduling frames). Mitigation: always run
  `flutter test --timeout 30s` so hangs become failures.
- `test/scratch_probe_test.dart` was written to probe the binders-list
  hang (bounded pumps instead of `pumpAndSettle`).

## Current session (3) progress

- [x] Confirmed both agent merges landed; integration diff reviewed —
      wiring is complete per the PHASE4_SESSION2_HANDOFF checklist.
- [x] `flutter analyze` clean (19 pre-existing infos only).
- [x] Root-caused the test hangs. Two separate things:
      1. **Real failure**: binders-list empty-state test (and the probe)
         died on flutter_test's `!timersPending` check — drift closes
         query streams with zero-duration timers when the ProviderScope
         is disposed at teardown, and nothing pumps them. Fixed with an
         explicit `unmountAndFlush` helper at the end of each test in
         `binders_list_screen_test.dart`: pump `SizedBox.shrink()`, then
         `pump(const Duration(milliseconds: 1))` — the nonzero duration
         is required, a bare `pump()` does not advance fake time.
      2. **Suite wedge**: after that pending-timer failure, the
         flutter_tester process wedges (0 CPU, never exits) and the whole
         run stalls; `--timeout 30s` does NOT rescue it because
         `testWidgets` has its own 10-min default that the CLI flag
         doesn't shorten. A suite that stalls right after a `[E]` failure
         line is this — fix the failure, the wedge goes away. The stuck
         test shown by the reporter (`query_filter_builder_test`) was an
         innocent bystander; it passes alone in 9s.
- [x] Deleted `test/scratch_probe_test.dart` (debug artifact) and
      `test/features/placeholder_screens_test.dart` (all its screens are
      real now, each covered by a dedicated test file; the
      BindersListScreen one pumped without ProviderScope and failed).
- [x] `binders_list_screen_test.dart` green in isolation (4/4, 5s).
- [x] Full suite green: **698 tests pass in ~61s** (exit 0). The suite
      was never slow — every stall was the wedge described above.
- [x] Closed `BinderManager-y54` / `BinderManager-2po` (agent work
      merged); filed `BinderManager-0xg` (P3, §11 placement line,
      deferred from integration).
- [ ] Commit integration (`BinderManager-2xd`).
- [ ] `flutter build web` gate — running.
- [ ] Acceptance pass (PHASE4_HANDOFF "Verify" list) in browser via
      `flutter run -d web-server --web-port=<fresh port>`.
- [ ] Push branch; hand off.

## Beads snapshot

- Closed this session: `BinderManager-y54` (Agent G), `BinderManager-2po`
  (Agent H) — both merged.
- In progress: `BinderManager-2xd` (integration — this working tree).
- Open: `BinderManager-0xg` (P3, §11 placement line, deferred),
  `BinderManager-0eq` (JSON export/import durability net — do not let
  slip past early Phase 5), `apy` (P2 multi-tab OPFS), `b2r`, `bqq`
  (P3 bugs).

## Gotchas (cumulative)

- **Drift + widget tests:** any `testWidgets` whose tree holds live drift
  `watch()` stream subscriptions (via StreamProviders and real in-memory
  DBs) can fail `!timersPending` at teardown AND wedge the tester process
  after the failure, stalling the whole run. End such tests with
  `await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 1));` (see
  `unmountAndFlush` in `binders_list_screen_test.dart`). The nonzero pump
  duration is load-bearing.
- **`flutter test` runs:** stream output to a file and poll it (never
  pipe through `Select-Object`/`head` — they buffer everything). A run
  that stalls right after an `[E]` line is the wedge above; testers
  sitting at 0 CPU for minutes right after start is just kernel
  compilation. `--timeout 30s` helps plain tests but does NOT bound
  `testWidgets` (10-min internal default).
- Background agents die silently on plan session limits; worktree state
  is the only artifact. Check worktrees before assuming loss.
- Run `flutter pub get` + `dart run build_runner build
  --delete-conflicting-outputs` in a worktree before judging compile
  state (`.g.dart` is gitignored).
- `git commit -F <file>` for multi-line messages on PowerShell 5.1.
- Fakes must mirror every public member of the real class.
- `bd update --claim` doesn't set in_progress on blocked issues; use
  `--status=in_progress` explicitly after unblocking.
