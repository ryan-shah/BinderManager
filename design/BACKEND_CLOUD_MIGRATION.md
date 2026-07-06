# BinderManager — Backend / Cloud Migration Plan

**Status:** proposal (post-Phase 4) · **Last updated:** 2026-07-06 · **Inputs:** `DESIGN.md` (D1–D13),
`PHASE4_CURRENT_STATUS.md` (Phase 4 complete on `phase-4/allocation-and-commit`), code survey of that
branch.

This document evaluates which components of BinderManager would be better served by a backend cloud
service instead of running in the local browser, and lays out a phased migration path. It is scoped
by three decisions confirmed 2026-07-06:

1. **Stack:** evaluate and recommend one (optimizing cost, ops burden, and fit).
2. **User data:** phased — a backup/restore durability net first, then multi-device sync with
   accounts.
3. **Compute:** the query engine and allocation **stay local** (D12's local-first architecture
   holds); the cloud provides *data services*.

---

## 1. Purpose & principles

BinderManager is local-first by design (D12): the D5 query engine and D6 allocator must run over
the user's private inventory joined to the ~100k-printing corpus, offline, with sub-second latency
for the binder editor's live preview. Nothing in Phase 4's completion changes that. What Phase 4
*does* sharpen is where the browser is the wrong tool:

- The **~150 MB corpus download + parse** runs on every first launch and every "Refresh data"
  (D11), identical for every user, char-by-char on the browser's **main isolate**. DESIGN.md §5
  already names this "web technical risk concentrated in build step 1".
- **User data durability** rests on OPFS, which is evictable and per-origin; clearing site data
  wipes the collection (`BinderManager-apy` also tracks a multi-tab OPFS wedge). JSON
  export/import (`BinderManager-0eq`, still open) is the v1 net; DESIGN.md already says "cloud
  sync is the eventual answer".
- Phase 5's flip-through UI renders 9–18 card images per spread; there is **no image cache** yet
  (D11 names a lazy cache as explicit Phase 5 scope).

**Principles for every service below:**

- **Cloud services are data services, never compute the core loop depends on.** The app keeps
  working fully offline after the corpus is local; a dead backend degrades to today's behavior.
- **Each service is independently adoptable** — no big-bang migration, no service depends on
  another landing first (except where phased below).
- **The client stays the source of truth for user data** until Phase B sync deliberately makes the
  server authoritative for conflict resolution.
- **Prefer zero-server (static artifact + CDN) over serverless over managed server** — this is a
  hobby-scale product; ops burden and cost floor matter more than scale ceiling.

---

## 2. Component-by-component evaluation

| Component | Today (in browser) | Verdict | Service |
|---|---|---|---|
| Corpus download + parse (D11) | 150 MB JSON streamed & parsed on main isolate | **Move** | C1 corpus prep pipeline |
| Price refresh (D4 snapshot) | Full corpus re-download | **Move** | C2 price delta feed |
| User data durability (D12) | OPFS + (planned) JSON export | **Move, phased** | C3 backup → C4 sync |
| Query engine (D5) | AST→SQL over local corpus+inventory | **Stay local** | — |
| Allocation + commit/rollback (D6/D7) | Pure Dart over local DBs | **Stay local** | — |
| Card images (D11) | `Image.network` direct to Scryfall CDN | **Stay client-side** (cache locally) | optional C5 artifact |
| Deckbuilder URL sync (deferred) | n/a | **Needs a tiny proxy when built** | C5 CORS proxy |
| Import parsing (ManaBox CSV, decklists, DelverLens) | Local parse | **Stay local** | — |

### 2.1 Move — Corpus preparation service (highest value, zero servers)

**Today.** `lib/core/import/scryfall_downloader.dart` resolves the bulk URI from
`https://api.scryfall.com/bulk-data` and streams the ~150 MB Default Cards JSON;
`lib/core/import/scryfall_parser.dart` extracts card objects with a hand-written incremental JSON
scanner and batch-inserts 500 rows at a time into the drift corpus DB
(`lib/core/database/corpus_database.dart`, schemaVersion 3). All of it runs on the UI isolate —
the only worker in the app is drift's DB worker (`web/drift_worker.dart`). Every user performs the
same work on the same public data, and repeats it on every D11 refresh.

**Proposal.** A **nightly scheduled job** (GitHub Actions cron — the repo already runs Actions for
gh-pages deploys and PR previews) that:

1. Downloads the Scryfall Default Cards bulk file.
2. Runs the existing mapping logic (a small Dart CLI under `tool/`, reusing
   `scryfall_parser.dart`'s `_mapToCompanion` mapping and the drift schema — one parser, two
   entry points) against a native SQLite file.
3. Emits a **pre-built, pre-indexed, gzipped SQLite corpus artifact** plus a small JSON manifest
   `{schemaVersion, builtAt, sha256, sizeBytes, downloadUrl}`.
4. Publishes both to static hosting (see §3 for GitHub Releases vs R2).

The client's corpus import gains a fast path: fetch the manifest, verify
`schemaVersion == CorpusDatabase.schemaVersion`, stream-download the artifact, decompress, and
install it as the corpus DB file (on web: write into OPFS and (re)open via the existing
`connect()` path in `lib/core/database/connection/web.dart`; on native: write the `.sqlite` file
directly). `corpus_meta.imported_at` comes from the manifest's `builtAt`.

**What this buys:**

- First-run friction drops from "download 150 MB **and** parse it in the tab" to "download one
  ~smaller compressed DB file" — the parse, `jsonDecode`, and index-build all move server-side.
- "Refresh data" (a D7 change trigger via `corpus_refresh_listener.dart`) gets dramatically
  cheaper, making the ~7-day staleness nudge realistic instead of a 150 MB tax.
- The main-isolate parse jank disappears entirely (related, but not identical, to
  `BinderManager-30d`'s editor-load perf — that one is fixed locally, see §2.4).

**Keep the current direct-Scryfall path as fallback.** If the manifest is unreachable or its
schemaVersion doesn't match the client, fall back to today's download+parse. This also keeps the
app buildable/testable with zero infrastructure and honors the "dead backend degrades to today"
principle.

- **Rationale:** the work is user-independent, public-data-only, and embarrassingly cacheable;
  it is the textbook case for precomputation. Zero servers: a cron job and a static file.
- **Tension:** *schema-version skew* — a deployed client and the nightly artifact must agree on
  the drift schema. Mitigate by keying artifacts by schemaVersion (publish
  `corpus-v3-YYYYMMDD.sqlite.gz`, keep the last artifact per live schema version until clients
  move on) and always having the direct-Scryfall fallback. Also *redistribution*: Scryfall bulk
  data is free to use, but confirm attribution requirements for shipping a derived artifact (§5).

### 2.2 Move (follow-on) — Price delta feed

Prices are the only corpus fields that change meaningfully day to day (D4 snapshot pricing:
`priceUsd`, `priceUsdFoil`, `priceUsdEtched`, `priceEur`, `priceEurFoil` on the `cards` table).
The same nightly job can additionally emit a compact **price file** — `scryfallId → prices`, full
or delta against the previous artifact — so "Refresh data" between corpus rebuilds becomes a
small download + `UPDATE` pass instead of any re-import. A price-only refresh still advances the
D4 snapshot, still fires the `priceRefresh` D7 change trigger, and still stages binder diffs.

- **Rationale:** rides the C1 pipeline for near-zero marginal cost; turns the most common refresh
  motivation (prices moved) into the cheapest operation in the app.
- **Tension:** new-printings still require a full corpus artifact; the client needs a simple rule
  ("price file applies only on top of corpus `builtAt` ≥ X, else take the full artifact").

### 2.3 Move (phased) — User data backup → sync service

**Today.** The user DB (`lib/core/database/user_database.dart`, schemaVersion 2 — `stacks`,
`decks`, `deck_entries`, `binders`, `binder_slots`, `snapshots`) lives only in OPFS/IndexedDB on
web. The schema is deliberately sync-ready per D12: every table uses client-generated **UUID v4
primary keys** and (except `snapshots`) `createdAt`/`updatedAt` timestamps. Binder committed
state already has a **versioned, portable JSON codec**
(`lib/core/state/binder_state_codec.dart`, `binderStateSchemaVersion = 1`, explicit field
writing, strict decode). What's missing for real sync: tombstones (deletes are hard `DELETE`s
with FK cascades), any logical clock / dirty tracking, a conflict policy — and the JSON export
itself (`BinderManager-0eq`).

**Phase A — account + blob backup/restore (the durability net, cloud edition).**

- Prerequisite: `BinderManager-0eq` JSON export/import of the full user DB. **The backup payload
  is the export payload** — extend the `binder_state_codec.dart` pattern (versioned envelope,
  explicit fields, enums by name, UTC ISO timestamps) to cover stacks/decks/deck_entries too.
  One canonical serialization serves local file export, cloud backup, and (later) sync seeding.
- Service: an account (email magic-link or OAuth) plus versioned snapshot storage — upload the
  export blob on demand (and optionally after each D7 commit), list/restore on any device.
  Retain the last N backups.
- This alone solves OPFS eviction, browser-profile loss, and device migration, with a trivially
  simple server contract (auth + object storage). No server-side knowledge of the schema at all.

**Phase B — incremental multi-device sync.**

- **Schema prep now, while migrations are cheap** (user DB is at v2 with one shipped upgrade
  path): add a tombstone strategy (soft-delete column or a `deleted_rows` table capturing
  table+uuid+deletedAt — without it, last-writer-wins resurrects deleted rows), a per-device ID,
  and per-row `syncedAt`/dirty tracking. Keep writing `updatedAt` monotonically.
- Sync model: **row-level last-writer-wins** keyed on the existing UUID PKs, using `updatedAt`
  (+ device ID as tiebreak). The server holds a relational mirror of the user tables with
  per-user row-level security. `snapshots` sync as **immutable opaque blobs** (append-only
  history; never merged). The staged-but-uncommitted D7 diff is in-memory Riverpod state by
  design (`change_staging_service.dart`) and **never syncs** — planned state is always
  recomputable on the receiving device.
- LWW is acceptable here because concurrent multi-device editing of the *same row* is a corner
  case for a single-user physical-binder tool; the payoff (no CRDT machinery) matches the
  product's scale. Revisit only if real conflicts show up.

- **Rationale:** phased delivery means the risky part (merge semantics) ships only after the
  valuable part (never lose your collection) is already live; the D12 groundwork (UUIDs +
  timestamps) is exactly what Phase B consumes.
- **Tension:** accounts introduce the project's first PII and first mandatory ops surface —
  that's why Phase A's contract is kept to "auth + blob", deferring the relational mirror until
  sync earns it.

### 2.4 Stay local — Query engine (D5) and allocation/staging (D6/D7)

Confirmed, per the scoping decision, and the code agrees:

- The engine's differentiator (`have:`/`unused:`) already **joins the corpus and user DBs in
  Dart** (`lib/core/query/query_engine.dart` resolves a `ReservationSummary` and the compiler
  injects scryfall-ID sets, with a literal-`IN` path past 500 ids). Moving it server-side would
  require the inventory server-side first — inverting the whole phasing for no user-visible win.
- The binder editor's live match/fit/overflow preview (`AllocationPlanner.plan(draft: …)`)
  needs local-latency recompute; the allocator (`lib/core/allocation/allocator.dart`) is pure
  Dart over in-memory state and costs nothing to keep local.
- Offline operation after corpus download is a product promise (D11/D12).

`BinderManager-30d` (editor initial load blocks UI 15–25 s in debug) is a **local** fix — measure
a release build first, then move planner work off the main isolate / make recompute incremental.
A backend is not the answer to it, and this plan deliberately does not use perf as a pretext to
centralize compute.

### 2.5 Stay client-side (for now) — Card images

Phase 5's flip-through needs an image cache (D11 explicit scope), but the right first
implementation is **client-side caching of Scryfall's CDN**, not a backend image proxy:

- A service-worker `CacheStorage` layer (the app already ships a custom service worker,
  `web/coi_serviceworker.js`) or an OPFS-backed cache keyed by `scryfallId` + size covers the
  9–18-pockets-per-spread rendering without any infrastructure.
- A proxy would put Scryfall's image bandwidth on this project's bill and sit worse with
  Scryfall's guidance (cache on the client; don't hotlink-at-scale through a relay).
- Constraint to respect: the COOP/COEP setup uses COEP **`credentialless`** specifically so
  cross-origin Scryfall images keep loading without CORP headers — any caching layer must
  preserve that behavior (and Safari's non-isolated fallback path).

Optional later (C5): the corpus pipeline can pre-build **thumbnail sprites/packs** for the small
image size, turning first-flip of a binder page into one artifact fetch. Treat as an
optimization to measure into, not plan-critical.

### 2.6 Future service — CORS proxy for deckbuilder URL sync

Deckbuilder URL/API sync (D10, deferred) will need a **tiny serverless CORS proxy** when built —
Moxfield/Archidekt endpoints don't serve permissive CORS headers to a static-hosted origin. One
function, allowlisted upstreams, no state. Noted here so it's budgeted as part of that feature,
not discovered during it.

---

## 3. Stack recommendation

Two services with opposite shapes; pick per-service rather than one platform for both.

**Corpus pipeline (C1/C2): GitHub Actions cron + GitHub Releases.**
Zero new vendors, zero servers, $0 at this scale, and the repo already lives its CI life in
Actions (gh-pages deploy, PR previews). Releases gives versioned, CDN-backed, immutable artifact
hosting with checksums for free; the manifest JSON can live on the existing gh-pages origin.
*Upgrade path:* if artifact size/bandwidth ever outgrows Releases, move the artifact to
**Cloudflare R2 + CDN** (no egress fees) without changing the client contract — the manifest
indirection exists exactly so the download URL can move.

**Backup/sync (C3/C4): Supabase.**
Managed Postgres + auth + object storage + row-level security in one free-tier-friendly product,
with an official Dart/Flutter SDK:

- Phase A uses only **Auth + Storage** (blob per backup, RLS policy "owner only") — minimal
  integration surface, no schema on the server.
- Phase B's relational mirror is **plain Postgres**, which maps naturally onto the drift schema
  (UUID PKs, timestamps), with RLS as the multi-tenancy story — no bespoke API server to run.
- Runner-up: **Cloudflare Workers + D1/R2** — cheaper at scale and pairs with the R2 upgrade
  path above, but requires assembling auth + API + storage by hand; wrong trade at hobby scale.
- **Lock-in mitigation:** the canonical user-data format is the client's versioned export JSON
  (§2.3), not any server schema; Phase A is "auth + put/get blob" replaceable in an afternoon;
  keep Phase B's sync protocol a thin document (rows in, rows out, LWW) rather than adopting a
  vendor-proprietary sync SDK.

---

## 4. Migration phases

Each phase is independently shippable and leaves the app fully functional if the next never
happens. Sequencing interleaves with the remaining app phases (Phase 5 UI, then fast-follows).

### C1 — Corpus build pipeline + client prebuilt-corpus path

- **Scope:** Dart CLI corpus builder (reuses parser mapping + drift schema); nightly Actions
  workflow publishing `corpus-v{schemaVersion}-{date}.sqlite.gz` + manifest; client fast path
  (manifest check → download → install into OPFS/file) with direct-Scryfall fallback; wire into
  onboarding and the Settings "Refresh data" action (same `corpusImportProvider` state machine —
  phases/progress UI already exist).
- **Prerequisites:** none. Can land alongside Phase 5 and directly improves it.
- **Client changes:** new download/install path in the corpus import flow; version check;
  fallback logic. No schema change.
- **Risks:** schema-version skew (mitigated by versioned artifacts + fallback); OPFS file
  install path needs care on web (write while DB closed, then open); Scryfall attribution (§5).

### C2 — Price delta refresh

- **Scope:** nightly price file (full `scryfallId → prices` map, gzipped, or delta vs previous);
  client "Refresh prices" applies `UPDATE`s, advances `imported_at`, fires the existing
  `priceRefresh` change trigger.
- **Prerequisites:** C1 (same pipeline and manifest).
- **Client changes:** small — a second, cheaper refresh action; rule for when a full corpus
  re-download is required instead.
- **Risks:** low; correctness rule is "price file only applies atop a compatible corpus build".

### C3 — JSON export/import → accounts + blob backup/restore

- **Scope:** finish `BinderManager-0eq` (full user-DB export/import via the extended
  versioned-codec pattern; Settings §12 actions) — this ships value with **no backend at all**;
  then add Supabase Auth + Storage: sign-in, "Back up now", auto-backup after commit (optional),
  list/restore backups on any device.
- **Prerequisites:** none for export/import (it's overdue Phase-4 tail); export lands before the
  cloud half.
- **Client changes:** export/import module + settings UI; then a thin `SyncService` for
  auth/upload/download; no user-DB schema change.
- **Risks:** first PII/account surface (keep scope to auth+blob); restore semantics must be
  whole-DB replace with an explicit confirm (mirrors the D8 Replace mental model).

### C4 — Sync-schema prep → incremental multi-device sync

- **Scope:** user-DB migration (v3): tombstones, device ID, per-row `syncedAt`/dirty flags; then
  the Phase-B row-level LWW sync against a Supabase Postgres mirror with RLS; snapshots sync as
  immutable blobs; conflict policy documented and tested (delete-vs-edit, edit-vs-edit, clock
  skew with device-ID tiebreak).
- **Prerequisites:** C3 (accounts exist; backup is the safety net *for* sync bugs). Do the
  schema-prep migration **early** (it can ship with C3 or even Phase 5) — it's cheap now and
  expensive later.
- **Client changes:** migration + repository-layer discipline (soft-delete instead of hard
  delete, dirty marking); sync engine; sync status UI.
- **Risks:** the real ones — delete loss without tombstones (hence prep-first), merge semantics,
  multi-tab (`BinderManager-apy`) interacting with sync (two tabs syncing one OPFS DB; consider
  leader election before enabling auto-sync on web).

### C5 — Opportunistic

- Client image cache for Phase 5 (service-worker CacheStorage or OPFS; respect COEP
  `credentialless`); optional thumbnail-pack artifact from the C1 pipeline if measurements say
  so; CORS proxy function when deckbuilder URL sync gets built.

---

## 5. Open questions / risks

- **Scryfall redistribution/attribution:** bulk data is provided for reuse, but confirm the
  current guidelines for redistributing a *derived database* (attribution text in-app and in the
  artifact manifest; no implication of endorsement). Check before C1 publishes publicly.
- **Corpus artifact compatibility window:** how many schema versions to keep publishing while
  deployed clients lag (proposal: current + previous; fallback covers the rest).
- **Auth on a static origin:** Supabase OAuth redirect flows on gh-pages hosting (works, but
  verify redirect-URL handling with the hash-based router) — magic-link email may be the
  smoother v1.
- **Multi-tab + sync:** `BinderManager-apy` (OPFS wedge) becomes more visible once a background
  sync loop writes to the DB; C4 should include a tab-leadership decision.
- **Backup size:** the user DB export is small (text rows, no images), but auto-backup-per-commit
  should be debounced and capped (retain last N) to stay comfortably inside free-tier storage.

---

## 6. Follow-up issues to file

`bd` was not available in the environment where this document was written; file these in beads at
next opportunity (suggested priorities in parentheses):

1. **C1 corpus build pipeline + client prebuilt-corpus path** (P2) — depends on nothing; biggest
   web-risk reduction available.
2. **C2 price delta refresh** (P3) — blocked by C1.
3. **C3 cloud backup/restore (accounts + blob)** (P2) — blocked by `BinderManager-0eq` (which
   stays its own P1 issue and ships first, backend-free).
4. **C4a sync-schema prep migration (tombstones, device id, dirty flags)** (P2 — cheap now,
   expensive later; can ship well before sync itself).
5. **C4b incremental multi-device sync** (P3) — blocked by C3 + C4a; revisit `BinderManager-apy`
   as part of it.
6. **C5 Scryfall attribution/licensing check for redistributed corpus artifact** (P2 — gates C1's
   public publish step).
