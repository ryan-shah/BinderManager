# BinderManager

A Magic: The Gathering collection tool focused on **binder management**. Given an imported collection and decklists, define binders by rules and the app auto-fills each binder with idle cards — cards you own but aren't using in any deck.

## Current Status

**Phase 1 complete — corpus pipeline + app shell.**

### What's implemented
- **Corpus data pipeline:** Scryfall Default Cards bulk download with streaming parse, batch insert into drift/SQLite database. Platform-conditional connection factory (native SQLite + sqlite3.wasm/OPFS for web).
- **App shell:** Desktop sidebar (208px, dark) + top bar with data freshness indicator. Mobile bottom navigation bar. Responsive breakpoint at 808px.
- **Onboarding screen:** First-run flow with download button, progress bar, and web storage consent banner.
- **Router with auth guard:** GoRouter with onboarding redirect when corpus hasn't been downloaded.
- **Design token theme:** Warm-neutral palette, WUBRG+CM mana pip colors, two-voice typography (Helvetica + monospace), spacing, shadows, binder skeuomorphic tokens.
- **Riverpod providers:** Corpus database singleton, corpus readiness check, import pipeline with progress state.

### What's next
- **Phase 2:** Query engine (Scryfall-subset parser, AST, SQL compiler) + collection search screen UI

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
```

## Project Structure

```
lib/
  main.dart                    # Entry point (ProviderScope + MaterialApp.router)
  app/
    router.dart                # GoRouter with onboarding redirect
    theme.dart                 # Design tokens from STYLE_GUIDE.md
    responsive.dart            # Desktop/mobile breakpoint (808px)
  core/
    database/
      connection/              # Platform-conditional DB connection (native/web)
      tables/                  # Drift table definitions (corpus_tables)
      corpus_database.dart     # Drift database for Scryfall card data
    import/
      scryfall_downloader.dart # Bulk data download with progress
      scryfall_parser.dart     # JSON stream parse + batch insert
    models/
      card_identity.dart       # CardIdentity (scryfallId + finish)
  features/
    shell/                     # App shell (sidebar/bottom nav)
    onboarding/                # First-run corpus download flow
    binders_list/              # (placeholder)
    collection_search/         # (placeholder)
    decks/                     # (placeholder)
    settings/                  # (placeholder)
  shared/
    widgets/                   # Reusable components (data_freshness_banner)
    providers/                 # Riverpod providers (corpus_provider)
design/
  DESIGN.md                    # Locked design decisions (D1-D12)
  UI_COMPONENTS.md             # Screen specs (13 screens + reusable components)
  STYLE_GUIDE.md               # Visual design tokens
Wireframes/                    # Mid-fi wireframes (exported HTML)
```

## Design Documents

- **[DESIGN.md](design/DESIGN.md)** — Product design with 12 locked decisions covering card identity, pricing, query engine, allocation, state model, and architecture
- **[UI_COMPONENTS.md](design/UI_COMPONENTS.md)** — Detailed specs for all 13 screens plus reusable component library
- **[STYLE_GUIDE.md](design/STYLE_GUIDE.md)** — Comprehensive visual tokens extracted from wireframes
