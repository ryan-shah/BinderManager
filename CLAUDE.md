# Project Instructions for AI Agents

This file provides instructions and context for AI coding agents working on this project.

<!-- BEGIN BEADS INTEGRATION v:1 profile:minimal hash:7510c1e2 -->
## Beads Issue Tracker

This project uses **bd (beads)** for issue tracking. Run `bd prime` to see full workflow context and commands.

### Quick Reference

```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --claim  # Claim work
bd close <id>         # Complete work
```

### Rules

- Use `bd` for ALL task tracking — do NOT use TodoWrite, TaskCreate, or markdown TODO lists
- Run `bd prime` for detailed command reference and session close protocol
- Use `bd remember` for persistent knowledge — do NOT use MEMORY.md files

**Architecture in one line:** issues live in a local Dolt DB; sync uses `refs/dolt/data` on your git remote; `.beads/issues.jsonl` is a passive export. See https://github.com/gastownhall/beads/blob/main/docs/SYNC_CONCEPTS.md for details and anti-patterns.

## Session Completion

**When ending a work session**, you MUST complete ALL steps below. Work is NOT complete until `git push` succeeds.

**MANDATORY WORKFLOW:**

1. **File issues for remaining work** - Create issues for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **PUSH TO REMOTE** - This is MANDATORY:
   ```bash
   git pull --rebase
   git push
   git status  # MUST show "up to date with origin"
   ```
5. **Clean up** - Clear stashes, prune remote branches
6. **Verify** - All changes committed AND pushed
7. **Hand off** - Provide context for next session

**CRITICAL RULES:**
- Work is NOT complete until `git push` succeeds
- NEVER stop before pushing - that leaves work stranded locally
- NEVER say "ready to push when you are" - YOU must push
- If push fails, resolve and retry until it succeeds
<!-- END BEADS INTEGRATION -->


## Phase Status Document (MANDATORY)

Long sessions on this project have repeatedly died to timeouts and plan
limits mid-task, losing context. To make every session resumable:

- Each phase keeps a **living status doc** at
  `design/PHASE<N>_CURRENT_STATUS.md` (e.g. `design/PHASE4_CURRENT_STATUS.md`).
- **At session start:** read the current phase's status doc first (plus
  `bd prime` output). It says exactly where the last session stopped.
- **During the session:** update the doc at every meaningful checkpoint —
  after merges, after test runs, when starting/finishing a work item, and
  especially BEFORE kicking off anything long-running (test suites,
  builds, background agents). Assume the session can be killed at any
  moment; the doc must always reflect reality.
- **At session end:** update it as part of the close protocol, then push.
- Beads remains the source of truth for *issues*; the status doc is the
  narrative "where exactly were we" layer (uncommitted state, in-flight
  worktrees, known-failing tests, next command to run).
- When a phase completes, fold anything durable into the next phase's
  handoff doc; the status doc for a finished phase stops being updated.

## Build & Test

Flutter web app (Dart). Codegen via build_runner (`.g.dart` is gitignored).

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # after schema/table changes, and in fresh worktrees
flutter analyze            # gate: no warnings/errors (infos OK)
flutter test --timeout 30s # gate: ALWAYS pass --timeout (see below)
flutter build web          # gate before ending a phase session
```

**Test-run rules (learned the hard way, 2026-07-05):**

- The full suite is FAST (~700 tests in ~1 min). If a run stalls for
  minutes, it is wedged — do not just wait.
- **Known wedge:** a `testWidgets` failure of the form "A Timer is still
  pending" (drift closes query streams with zero-duration timers at
  ProviderScope disposal) can wedge the flutter_tester process right
  after the `[E]` line, stalling the whole run at 0 CPU. Fix: end any
  widget test whose tree holds live drift `watch()` streams with
  `await tester.pumpWidget(const SizedBox.shrink()); await
  tester.pump(const Duration(milliseconds: 1));` — the nonzero duration
  is required (a bare `pump()` does not advance fake time). See
  `unmountAndFlush` in `test/features/binders_list/binders_list_screen_test.dart`.
- `--timeout 30s` bounds plain `test()`s but NOT `testWidgets` (its
  10-minute internal default wins), so it will not rescue a wedged run.
- Run suites in the background, redirect output to a file, and poll the
  file — never pipe through buffering commands (`Select-Object`, `head`)
  or you fly blind. Testers idling at 0 CPU right after run start is
  normal kernel compilation, not a hang.
- Checkpoint the phase status doc BEFORE starting a long run.

## Conventions & Patterns

- `git commit -F <file>` for multi-line commit messages (PowerShell 5.1).
- Test fakes must mirror every public member of the class they fake.
- Worktree agents: commit with a clear prefix, never push; worktree state
  is the only artifact if the agent dies — check worktrees before
  assuming work was lost.
- Design docs live in `design/` (DESIGN.md, per-phase handoffs, the
  current-status doc above).
