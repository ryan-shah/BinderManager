# Phase 4 — Current Status

> **Living document.** Update this file as work progresses so any session
> (including one killed by a timeout or plan limit) can resume from here.
> Beads (`bd prime` / `bd ready`) is still the source of truth for issues;
> this doc is the narrative "where exactly were we" layer on top.
>
> Last updated: 2026-07-05 (session 3 close — integration DONE, acceptance
> pass DONE).

## TL;DR

**Phase 4 core is complete.** Agents G and H merged, integration
committed (`c27dc98`), all gates green (analyze info-only, 698 tests in
~61s, build web), and the full in-browser acceptance pass ran clean on
2026-07-05 (see "Acceptance pass results" below). `BinderManager-y54`,
`-2po`, `-2xd` are closed. Remaining Phase 4 tail: `BinderManager-0eq`
(JSON export/import durability net — do not let slip), `-0xg` (§11
placement line), `-30d` (editor load perf), and the pre-existing P2/P3
bugs.

## Acceptance pass results (2026-07-05, in-browser)

Ran via `flutter run -d web-server --web-port=8177`, debug 5k quick
import, 14-stack ManaBox CSV built from real head-of-bulk Scryfall IDs
(saved with a paired decklist in `examples/` — see `examples/README.md`).

- ✅ CSV import: 14/14 matched (incl. Mystical Tutor nonfoil ×2 + foil ×1).
- ✅ Two overlapping binders (Premium `usd>=10` 3×3×1 single, priority 1;
  Instants `t:instant` 2×2×1 single): MT stacks claimed by Premium only —
  top priority wins; editor live preview showed matches/eligible/fits/
  overflow correctly at every step.
- ✅ Review screen: adds with exact page/side/pocket, price-desc order,
  ×N quantities; overflow panel ("4 matched but didn't fit" = the 4
  cheapest instants); list rows show fill gauges + amber overflow badge.
- ✅ Commit → "Planned and committed state now match".
- ✅ D13: assembled deck reserving 1 MT consumed the CHEAPEST finish
  (nonfoil $16.85, not foil $26.47) — staged Remove×2/Add×1 on the
  nonfoil slot only; committed.
- ✅ Rule edit (usd>=10 → usd>=15): staged 1 remove (Birds of Paradise);
  **Roll back restored the query AND placements**; re-edit → re-commit OK.
- ✅ Priority reorder (drag): staged 2 adds · 4 removes (Instants steals
  MT stacks, bumps its 2 cheapest committed to overflow); roll back
  restored the order and diff.
- ✅ D13 correction: deck printing swap DMR→PRM (unowned promo) staged
  Remove×1/Add×2 restoring the freed nonfoil copy; committed.
- ⏭️ Pinned-survives-reflow: no pin UI this phase (engine unit-tested).
- ⏭️ Refresh data live check: skipped — same-day bulk ⇒ prices identical ⇒
  diff provably empty; the priceRefresh wiring is widget-tested
  (`corpus_refresh_listener_test`). Re-check manually after a real
  price-moving refresh in Phase 5.

Observations filed: `BinderManager-30d` (editor initial load blocks UI
15-25s; renderer went unresponsive once). Review screen briefly shows
raw IDs while name lookups resolve (loading flash, cosmetic only).
Reorder drag needs a slow drag gesture (fast synthetic drags don't
register — that's Flutter gesture arena behavior, not a bug).

## Branch state

`phase-4/allocation-and-commit` (pushed; also contains `3cdeaeb` —
`examples/` + README refresh from a background agent):

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
- [x] `flutter build web` green (73s).
- [x] Integration committed (`c27dc98`) + docs/CLAUDE.md (`fe3d85d`),
      **pushed to origin** (branch at `fe3d85d`).
      Note: do NOT `git pull --rebase` on this branch — it tries to
      flatten the agent merge commits and conflicts; fetch + compare,
      then plain `git push`.
- [x] Acceptance pass — done, see "Acceptance pass results" above.
- [x] Closed `BinderManager-2xd`; final push.

## Next session (Phase 4 tail / Phase 5 prep)

1. `BinderManager-0eq` — JSON export/import of the user DB (durability
   net). Highest priority of the tail; do not let it slip.
2. `BinderManager-30d` — editor load perf (measure release build first).
3. `BinderManager-0xg` — §11 card/stack detail placement line.
4. Known bugs: `apy` (P2 multi-tab OPFS wedge), `b2r`, `bqq` (P3).
5. Phase 5 planning per DESIGN build order.

## Beads snapshot

- Closed this session: `BinderManager-y54` (Agent G), `BinderManager-2po`
  (Agent H), `BinderManager-2xd` (integration + acceptance).
  NOTE: a background agent's `.beads/issues.jsonl` commit re-OPENED
  y54/2po once — if statuses look wrong after a pull, re-check with
  `bd show` before trusting the jsonl.
- Open: `BinderManager-0eq` (P1 durability net), `BinderManager-30d`
  (P3 editor perf), `BinderManager-0xg` (P3, §11 placement line),
  `apy` (P2 multi-tab OPFS), `b2r`, `bqq` (P3 bugs).

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
