# BinderManager

A Magic: The Gathering collection tool focused on **binder management**. Given an imported collection and decklists, define binders by rules and the app auto-fills each binder with idle cards — cards you own but aren't using in any deck.

## Current Status

**Phase 0 complete — project scaffold.** No application features yet.

### What's implemented
- Flutter project targeting **web + Android**
- Design token theme from the style guide (warm-neutral palette, WUBRG+CM mana pip colors, two-voice typography, spacing, shadows, binder skeuomorphic tokens)
- GoRouter with stub routes for 4 primary destinations (Binders, Collection, Decks, Settings)
- Riverpod state management wired up
- Directory structure for core/, features/, shared/ architecture layers

### What's next
- **Phase 1:** Corpus data pipeline (Scryfall bulk download + drift/SQLite + OPFS for web) and app shell (sidebar/bottom nav + onboarding screen)

## Tech Stack
- **Flutter + Dart** (single codebase, web + Android)
- **drift** (SQLite ORM — native + sqlite3.wasm/OPFS on web)
- **Riverpod** (state management)
- **GoRouter** (declarative routing)

## Build & Run

```bash
flutter pub get
flutter run -d chrome    # web
flutter run -d android   # Android emulator/device
```

## Project Structure

```
lib/
  main.dart              # Entry point
  app/                   # Router, theme, responsive helpers
  core/                  # Business logic (database, query engine, allocation, import)
  features/              # Screen-level UI (one directory per screen)
  shared/                # Reusable widgets and Riverpod providers
docs/
  DESIGN.md              # Locked design decisions (D1-D12)
  UI_COMPONENTS.md       # Screen specs (13 screens + reusable components)
  STYLE_GUIDE.md         # Visual design tokens
Wireframes/              # Mid-fi wireframes (exported HTML)
```

## Design Documents

- **[DESIGN.md](docs/DESIGN.md)** — Product design with 12 locked decisions covering card identity, pricing, query engine, allocation, state model, and architecture
- **[UI_COMPONENTS.md](docs/UI_COMPONENTS.md)** — Detailed specs for all 13 screens plus reusable component library
- **[STYLE_GUIDE.md](docs/STYLE_GUIDE.md)** — Comprehensive visual tokens extracted from wireframes
