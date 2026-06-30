# BinderManager — Visual Style Guide

**Status:** v1 · **Last updated:** 2026-06-30 · Companion to [`DESIGN.md`](./DESIGN.md) and [`UI_COMPONENTS.md`](./UI_COMPONENTS.md)

Design tokens and visual rules extracted from the mid-fi wireframes. Everything an implementer
needs to stay on-brand without eyedropping the source files.

---

## 1. Design philosophy

**Warm-neutral utility UI** with one deliberate exception: the binder view is **skeuomorphic**.

- The palette is warm gray (yellow-brown undertone), never blue-gray or pure gray.
- The only chromatic hues are **WUBRG mana pips** and **amber warnings** — there is no brand
  accent color. The darkest neutral (`#2a2820`) serves as the primary action color.
- Two typographic voices: **Helvetica** for readable content, **monospace** for system/status
  metadata. The contrast between them is a core visual signature.
- Data density is high but breathing room comes from generous padding inside cards and panels,
  not from whitespace between them.

---

## 2. Color palette

### 2.1 Neutrals (the core palette)

| Token | Hex | Usage |
|-------|-----|-------|
| `neutral-950` | `#22211d` | Sidebar background, dark hero cards |
| `neutral-900` | `#2a2820` | Primary text, primary buttons, active states |
| `neutral-800` | `#36352f` | Sidebar active nav item background |
| `neutral-700` | `#3a382f` | Secondary text (body copy in inputs/content) |
| `neutral-600` | `#6b6862` | Muted text, secondary actions, inactive icons |
| `neutral-500` | `#8a877e` | Tertiary text (annotations, wireframe labels) |
| `neutral-400` | `#9a978d` | Placeholder text, metadata, gauge fill |
| `neutral-350` | `#b3b0a8` | Page labels inside binder |
| `neutral-300` | `#bdbab2` | Disabled text, hints, search placeholder |
| `neutral-250` | `#cfccc2` | Sidebar text, drag handles (rest), empty borders |
| `neutral-200` | `#d8d6cd` | Borders (standard), button outlines |
| `neutral-150` | `#e6e4dc` | Gauge track, stepper inactive, dividers |
| `neutral-100` | `#ececea` | Card borders, section dividers, rule lines |
| `neutral-75`  | `#f1efe9` | Tinted backgrounds (muted sections, chips) |
| `neutral-50`  | `#faf9f6` | Subtle panel backgrounds, input fields |
| `neutral-0`   | `#fff`    | Card/panel surfaces, page backgrounds |

### 2.2 Amber (warnings, staleness, attention)

| Token | Hex | Usage |
|-------|-----|-------|
| `amber-bg` | `#f6f1e3` | Warning banner/card background |
| `amber-border` | `#e8e0c9` | Warning border |
| `amber-text` | `#7a6a3a` | Warning text, overflow badges |
| `amber-dot` | `#caa44e` | Staleness indicator dot, foil label color |
| `amber-btn-border` | `#d8caa0` | Warning action button border |

### 2.3 Semantic status

| Token | Hex | Usage |
|-------|-----|-------|
| `status-add-text` | `#1f5a33` | "ADD" badge text, "idle" badge, "owned" |
| `status-add-bg` | `#eef5ef` | "ADD" badge background, "idle" chip bg |
| `status-add-border` | `#cfe3d4` | Include set chip border |
| `status-remove-text` | `#7a2f1f` | "REMOVE" badge text, exclude chips |
| `status-remove-bg` | `#f6edea` | "REMOVE" badge background |
| `status-remove-border` | `#e6cabf` | Exclude set/treatment chip border |
| `status-move-bg` | `#f1efe9` | "MOVE" badge background |
| `status-move-border` | `#ddd9cf` | "MOVE" badge border |

### 2.4 WUBRG mana pips

Each color has a background, border, and text color. Pips are always circular.

| Mana | Background | Border | Text |
|------|-----------|--------|------|
| **W** (White) | `#f0ead0` | `#cdbf86` | `#6b5e2e` |
| **U** (Blue) | `#bcdcef` | `#6fa8cf` | `#1f5a7a` |
| **B** (Black) | `#c3bdb6` | `#847c72` | `#2c2722` |
| **R** (Red) | `#f0b3a2` | `#cf7f6a` | `#7a2f1f` |
| **G** (Green) | `#aed7b9` | `#6fae84` | `#1f5a33` |
| **C** (Colorless) | `#d9d4cd` | `#a39c91` | `#5a544b` |
| **M** (Multicolor) | `#e8d5a3` | `#c4a44e` | `#7a6a3a` |

### 2.5 Foil / finish indicator

| Token | Hex | Usage |
|-------|-----|-------|
| `foil-text` | `#caa44e` | "FOIL" label text, foil badge |

Etched has no special color in the wireframes — shown as a text label in the standard muted text
color (`neutral-400`).

---

## 3. Typography

### 3.1 Font stacks

| Voice | Stack | Role |
|-------|-------|------|
| **Content** | `'Helvetica Neue', Helvetica, Arial, sans-serif` | Headings, body, buttons, card names |
| **System** | `ui-monospace, monospace` | Labels, metadata, status badges, query syntax, prices |

The two-voice system is intentional: Helvetica carries the human-readable layer (card names,
titles, actions); monospace carries the machine/data layer (counts, prices, filter syntax, status
codes). Mixing them within a single row — e.g. card name in Helvetica, price in mono — is the
standard pattern, not an inconsistency.

### 3.2 Type scale

#### Content voice (Helvetica)

| Name | Weight | Size | Usage |
|------|--------|------|-------|
| `display` | 700 | 38px | Hero stat (idle value on dashboard) |
| `heading-xl` | 700 | 21px | Card detail title, deck detail title |
| `heading-lg` | 700 | 19px | Section titles (desktop) |
| `heading-md` | 700 | 17px | Mobile screen titles (app bar) |
| `heading-sm` | 700 | 15px | Card/binder names in lists |
| `heading-xs` | 700 | 14px | Mobile headers, sub-section titles |
| `body` | 600 | 13px | Primary body text, button labels |
| `body-sm` | 500 | 12px | Secondary body, descriptions |
| `body-xs` | 500 | 11px | Tertiary text, inline help |
| `button-lg` | 600 | 14px | Primary action buttons (full-width) |
| `button` | 600 | 12px | Standard buttons |
| `button-sm` | 600 | 11px | Small/compact buttons |

#### System voice (monospace)

| Name | Weight | Size | Extras | Usage |
|------|--------|------|--------|-------|
| `section-label` | 600–700 | 11–12px | uppercase, `letter-spacing: 0.06em` | Section headers (PREFERENCES, BINDERS, etc.) |
| `meta` | 500 | 11px | — | Status text, timestamps, descriptions |
| `query` | 500 | 12–13px | — | Query bar content, raw syntax |
| `stat-label` | 600 | 9–10px | uppercase | Stat labels (TOTAL VALUE, CARDS, etc.) |
| `tag` | 600 | 8–9px | uppercase, `letter-spacing: 0.04em` | Tags, badges (pin, +add, pull) |
| `badge` | 600–700 | 9px | — | Count badges, status indicators |
| `pip-text` | 700 | 9px | — | Single letter inside WUBRG pips |

### 3.3 Stat numbers

Stat tiles use Helvetica 700 at varying sizes depending on context:

| Context | Size | Example |
|---------|------|---------|
| Hero (dashboard) | 38px | `$4,210` |
| Panel stat | 20px | `$11,930`, `3,512` |
| Mobile stat | 26px (hero), 18px (secondary) | `$4,210`, `$11.9k` |
| Inline stat | 17–18px | `1,228` (parse summary) |

---

## 4. Spacing & layout

### 4.1 Spacing scale

| Token | Value | Usage |
|-------|-------|-------|
| `space-xs` | 4–5px | Tight gaps (pip-to-label, badge internal) |
| `space-sm` | 6–8px | Chip gaps, small element spacing |
| `space-md` | 10–12px | Standard element gaps, card padding |
| `space-lg` | 14–16px | Section gaps, panel padding |
| `space-xl` | 18–20px | Page padding, major section spacing |
| `space-2xl` | 24px | Large section breaks |

### 4.2 Content widths

| Context | Width |
|---------|-------|
| Desktop sidebar | 208px |
| Desktop sidebar (collapsed) | ~42px (icon-only) |
| Desktop right rail / info panel | 248–260px |
| Desktop binder editor preview pane | 320px |
| Desktop main content | flex (fills remaining) |
| Mobile screen | 320px content area (within device frame) |
| Settings max-width | ~760px |

### 4.3 Desktop shell layout

```
┌─────────┬──────────────────────────────────────┐
│ Sidebar │ Top bar (search + refresh + settings) │
│  208px  ├──────────────────────────────────────┤
│         │                                      │
│  nav    │         Main content pane             │
│  items  │         (route renders here)          │
│         │                                      │
│ binder  │                                      │
│ short-  │                                      │
│ cuts    │                                      │
│         │                                      │
│ collapse│                                      │
└─────────┴──────────────────────────────────────┘
```

### 4.4 Mobile shell layout

```
┌────────────────────┐
│    Status bar       │
├────────────────────┤
│ Title     actions   │  ← top app bar
├────────────────────┤
│                    │
│   Screen content    │
│                    │
│                    │
├────────────────────┤
│ Binders Collection │  ← bottom nav (4 items)
│ Decks   Settings   │
└────────────────────┘
```

---

## 5. Component tokens

### 5.1 Border radius

| Token | Value | Usage |
|-------|-------|-------|
| `radius-xs` | 3px | Tiny badges, qty chips |
| `radius-sm` | 4–5px | Pocket cells, progress bars, WUBRG pip toggles |
| `radius-md` | 6–7px | Chips, filter toggles, buttons |
| `radius-lg` | 8–9px | Input fields, segmented controls, action bars |
| `radius-xl` | 10–12px | Cards, panels, settings groups, binder pages |
| `radius-2xl` | 14px | Large modal cards (first-run) |
| `radius-pill` | 50% | Pips, circular buttons, FAB, refresh button |

### 5.2 Shadows

| Token | Value | Usage |
|-------|-------|-------|
| `shadow-card` | `0 1px 3px rgba(0,0,0,.08)` | Standard cards, panels |
| `shadow-drag` | `0 6px 16px rgba(0,0,0,.12)` | Dragging state (binder reorder) |
| `shadow-modal` | `0 10px 30px rgba(0,0,0,.16)` | Modal overlays, popover prompts |
| `shadow-fab` | `0 4px 12px rgba(0,0,0,.25)` | Floating action button |
| `shadow-device` | `0 4px 16px rgba(0,0,0,.18)` | Mobile device frame (wireframe only) |
| `shadow-binder-inset` | `inset 0 1px 4px rgba(0,0,0,.08)` | Binder surround inner shadow |
| `shadow-bottom-sheet` | `0 -4px 16px rgba(0,0,0,.08)` | Mobile bottom sheets |

### 5.3 Buttons

**Primary** (dark):
- Background: `neutral-900` (`#2a2820`)
- Text: `#fff`
- Border: `1px solid neutral-900`
- Radius: `radius-md` (7px)
- Padding: 7–8px vertical, 12–14px horizontal
- Font: `button` (600 12px Helvetica)

**Secondary** (outline):
- Background: `#fff`
- Text: `neutral-700` (`#3a382f`) or `neutral-600` (`#6b6862`)
- Border: `1px solid neutral-200` (`#d8d6cd`)
- Same radius, padding, font as primary

**Warning action** (amber outline):
- Background: `#fff`
- Text: `amber-text` (`#7a6a3a`)
- Border: `1px solid amber-btn-border` (`#d8caa0`)

**Circular icon button:**
- Size: 34px
- Border-radius: 50%
- Border: `1px solid neutral-200`
- Background: `#fff`

**FAB (mobile):**
- Size: 52px
- Border-radius: 50%
- Background: `neutral-900`
- Text: `#fff`, 28px, weight 300
- Shadow: `shadow-fab`

### 5.4 Chips & filter toggles

**Active (selected):**
- Background: `neutral-900` (`#2a2820`)
- Text: `#fff`
- Border: `1px solid neutral-900`

**Inactive (unselected):**
- Background: `#fff`
- Text: `neutral-600` (`#6b6862`)
- Border: `1px solid neutral-200` (`#d8d6cd`)

**Excluded (negative filter):**
- Background: `status-remove-bg` (`#f6edea`)
- Text: `status-remove-text` (`#7a2f1f`)
- Border: `1px solid status-remove-border` (`#e6cabf`)

**Included (positive, for set chips):**
- Background: `status-add-bg` (`#eef5ef`)
- Text: `status-add-text` (`#1f5a33`)
- Border: `1px solid status-add-border` (`#cfe3d4`)

**Applied filter chip (removable):**
- Background: `neutral-75` (`#f1efe9`)
- Text: `neutral-700` (`#3a382f`)
- Dismiss "×": `neutral-400` (`#9a978d`)

**All chips:** radius `radius-md` (6px), padding 4–5px vertical, 8–9px horizontal,
font 600 10–11px Helvetica.

### 5.5 Segmented controls

- Container: `1px solid neutral-200`, radius `radius-lg` (8px), overflow hidden
- Active segment: background `neutral-900`, text `#fff`
- Inactive segment: background `#fff`, text `neutral-600`
- Font: 600 12px Helvetica
- Padding: 7–8px vertical, 11–14px horizontal
- Used for: Replace/Append, Assembled/Shared, pocket layout (2×2/3×3/4×4), Single/Double

### 5.6 Cards & panels

**Standard card:**
- Background: `#fff`
- Border: `1px solid neutral-100` (`#ececea`)
- Radius: `radius-xl` (10px)
- Padding: 12–14px
- No shadow (shadow is on the outer shell, not individual cards)

**Stat tile:**
- Background: `neutral-50` (`#faf9f6`)
- Border: `1px solid neutral-100`
- Radius: `radius-xl` (10px)
- Padding: 12px

**Dark stat tile (hero):**
- Background: `neutral-950` (`#22211d`)
- Text: `#fff`
- Radius: `radius-xl` (12px)
- Padding: 18px

**Settings group:**
- Container: `1px solid neutral-100`, radius `radius-xl` (10px)
- Rows separated by `1px solid neutral-100` borders
- Row padding: 13px 14px

### 5.7 Progress / gauge bars

**Fill gauge (binder capacity):**
- Track: `neutral-150` (`#e6e4dc`), height 6–8px, radius 4–5px
- Fill: `neutral-400` (`#9a978d`)

**Download progress:**
- Track: `neutral-150`, height 8px, radius 5px
- Fill: `neutral-900` (`#2a2820`)

**Price slider:**
- Track: `neutral-150`, height 5–6px, radius 4px
- Active range: `neutral-400`
- Thumb: 13–16px circle, `#fff`, `2px solid neutral-900`

### 5.8 Toggle switch

- Track size: 36×20px, radius pill
- Track on: `neutral-900` (`#2a2820`), knob right
- Track off: `neutral-200` (`#d8d6cd`), knob left
- Knob: 16px circle, `#fff`, 2px inset from edge

### 5.9 Banners

**Warning/staleness banner (inline):**
- Background: `amber-bg` (`#f6f1e3`)
- Border: `1px solid amber-border` (`#e8e0c9`)
- Text: `amber-text` (`#7a6a3a`)
- Radius: `radius-lg` (9–10px) when standalone card; square when full-width strip

**Dark attention banner:**
- Background: `neutral-900` (`#2a2820`)
- Text: `#fff`
- Used for: pending changes pill, reorder diff banner

### 5.10 WUBRG+CM pip (mana color indicator)

- Default size: 15×15px (compact), 26×26px (filter toggle), 20×20px (card detail)
- Shape: circle (border-radius: 50%)
- Font: `pip-text` (700 9px monospace), single letter centered
- Seven pips: W, U, B, R, G, C (colorless), M (multicolor/generic)

**Filter pip states** (26×26px size, used in #6 filter rail and #8 binder editor):

| State | Border | Background | Text |
|-------|--------|------------|------|
| **Selected** | `2px solid neutral-900` (`#2a2820`) | per-color bg from §2.4 | per-color text from §2.4 |
| **Unselected** | `1px solid` per-color border from §2.4 | per-color bg from §2.4 | per-color text from §2.4 |
| **Deselected (off)** | `2px dashed neutral-250` (`#cfccc2`) | lightened bg (`#f3f1ec` for C, `#f5f0e3` for M) | `neutral-300` (`#bdbab2`) |

The deselected state appears when a color is explicitly excluded from a binder's content
rules — distinct from unselected (available but not active).

---

## 6. Binder skeuomorphic tokens

The binder view (#9) is the one deliberately non-flat surface. These tokens apply only within
the binder spread.

### 6.1 Binder structure

| Token | Hex | Usage |
|-------|-----|-------|
| `binder-surround` | `#d8d4ca` | Outer binder frame background |
| `binder-surround-border` | `#c9c4b8` | Outer frame border |
| `binder-page` | `#fbfaf6` | Page surface |
| `binder-page-border` | `#d4d0c6` | Page border |
| `binder-spine-light` | `#cfcabf` | Spine gradient edges |
| `binder-spine-mid` | `#bdb8ac` | Spine gradient center |
| `binder-ring-border` | `#efece4` | Ring outer border |
| `binder-ring-fill` | `#a8a296` | Ring center fill |

- Binder surround: radius `radius-xl` (10px), `shadow-binder-inset`
- Page: radius 6px (outer edge rounded, spine edge flat: `6px 2px 2px 6px` left, `2px 6px 6px 2px` right)
- Spine: 30px wide, linear gradient left→right
- Rings: 5 evenly spaced, 14px circles with 3px border

### 6.2 Pocket cell

| State | Border | Background | Opacity |
|-------|--------|------------|---------|
| **Committed** (normal) | `1px solid #c7c5bd` | Striped placeholder `45deg #eceae4 / #e4e2da` | 1.0 |
| **Empty** | `1px dashed #cfccc2` | `#f7f6f2` | 1.0 |
| **Ghost (to-add)** | `1px dashed #b9b6ad` | `#f4f3ef` | 0.92 |
| **Hatched (to-remove)** | `1px solid #b9b6ad` | Striped `45deg #e3e0d6 / #cfccc2` (tighter 4px) | 1.0 |
| **To-move** | `1px solid #9a978d` | Same as committed | 1.0 |

- Size: `aspect-ratio: 5/7` (card proportions)
- Radius: 4px (desktop), 5px (mobile)
- Padding: 4px
- Card name: 600 9px Helvetica, price in mono below

### 6.3 Page curl (mobile)

- Position: top-right corner of binder page
- Size: 34×34px
- Gradient: `linear-gradient(225deg, #cfccc2 0 50%, transparent 50%)`
- Radius: `0 12px 0 24px`

### 6.4 Page strip (desktop jump nav)

- Thumbnail size: 26×34px
- Inactive: `1px solid neutral-200`, background `#f1efe9`
- Active: `2px solid neutral-900`, background `#fff`, `shadow-card`

### 6.5 Page indicator dots (mobile)

- Inactive: 5×5px circle, `#cfccc2`
- Active: 16×5px rounded pill, `neutral-900`

---

## 7. Interaction patterns

### 7.1 Drag-to-reorder (binder list)

- **Rest:** border `neutral-100`, drag handle bars in `neutral-250`
- **Dragging:** border `neutral-900`, handle bars darken to `neutral-600`, `shadow-drag`
- Reordering triggers a change event → dark banner with "Review changes →"

### 7.2 Filter sync

Structured filters and the raw query bar are **always in sync**. Editing either updates the other.
Applied filters appear as removable chips below the query bar. The raw query is displayed in
monospace (`query` token) inside a bordered input with a "QUERY" label prefix in `neutral-300`.

### 7.3 Diff state visual language

The three diff types have a consistent badge + visual treatment used in both the binder view
(#9 pocket states) and the change review (#10 rows):

| Type | Badge color | Badge bg | Pocket treatment |
|------|------------|----------|------------------|
| **ADD** | `status-add-text` | `status-add-bg` | Ghost (dashed, faded) |
| **REMOVE** | `status-remove-text` | `status-remove-bg` | Hatched (tight diagonal stripe) |
| **MOVE** | `neutral-700` | `status-move-bg` | Solid border, "→ pg5" tag |

### 7.4 Card status badges

Used on card/stack tiles in the collection grid and card detail:

| Status | Text color | Background |
|--------|-----------|------------|
| `idle` | `status-add-text` | `status-add-bg` |
| `reserved` | `amber-text` | `amber-bg` |
| `{binder name}` | `neutral-600` | `neutral-75` |
| `pinned` | `#fff` | `neutral-900` |

---

## 8. Responsive breakpoints

The wireframes define two layout modes with no intermediate states:

| Mode | Behavior |
|------|----------|
| **Desktop** | Sidebar + top bar shell; multi-pane layouts (master-detail, two-pane editors); card grids 3–6 across; right rails for secondary info |
| **Mobile** | Bottom nav + top app bar; single-column layouts; 2-wide card grids; bottom sheets for filters/actions/prompts; FAB for primary creation actions |

The breakpoint between them is an implementation choice — the wireframes don't specify a pixel
value, but the sidebar width (208px) plus minimum useful content pane (~600px) implies ~808px
as a natural minimum for desktop mode.
