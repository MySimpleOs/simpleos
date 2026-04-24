# SimpleOS UI theme — token reference (§3a)

Single design system: **macOS / Apple HIG** (Sequoia-era neutrals + system blue).
All runtime values are **sRGB straight-alpha ARGB32** (`0xAARRGGBB`, `AA = 0xFF` today).

---

## 1. Key grammar (EBNF)

```ebnf
key        = segment { "." segment } ;
segment    = ( letter | "_" ) { letter | digit | "_" } ;
letter     = "a" … "z" ;
digit      = "0" … "9" ;
```

- Lowercase **ASCII only** (no Unicode keys).
- Dot-separated namespaces: `color.bg.base`, `radius.md`, `duration.fast`.
- State suffixes (same segment rules): `color.bg.surface_hover`, `color.bg.surface_pressed`, `color.bg.surface_selected`, `color.bg.surface_disabled`.

---

## 2. Token catalog (authoritative names)

### 2.1 Colors (`uint32_t` ARGB)

| Key | Role |
|-----|------|
| `color.bg.base` | Desktop / compositor clear behind windows |
| `color.bg.surface` | Window body, dock plate, cards |
| `color.bg.surface_elevated` | Title bars, popovers, modals |
| `color.bg.surface_hover` | Hover fill for chrome |
| `color.bg.surface_pressed` | Pressed fill |
| `color.bg.surface_selected` | Selection / highlighted row |
| `color.bg.surface_disabled` | Disabled chrome |
| `color.border.subtle` | Hairlines, dock top edge |
| `color.border.default` | Standard frame |
| `color.border.strong` | Emphasis / focus chrome |
| `color.text.primary` | Body and titles |
| `color.text.secondary` | Secondary labels |
| `color.text.tertiary` | Captions, placeholders |
| `color.text.disabled` | Disabled text |
| `color.accent.default` | Primary actions, key dock tile |
| `color.accent.hover` | Hover |
| `color.accent.pressed` | Pressed |
| `color.semantic.success` | Success / confirm accents |
| `color.semantic.warning` | Warning |
| `color.semantic.error` | Error |
| `color.semantic.info` | Info (often same hue family as accent) |
| `color.focus.ring` | Keyboard focus ring |

### 2.2 Radius (`int` dp, logical pixels)

| Key | Typical dp |
|-----|------------|
| `radius.none` | 0 |
| `radius.xs` | 4 |
| `radius.sm` | 6 |
| `radius.md` | 10 |
| `radius.lg` | 14 |
| `radius.xl` | 20 |
| `radius.full` | 9999 (pill; clamp in painter) |

### 2.3 Spacing (`unsigned` dp)

| Key | dp (4-pt grid) |
|-----|----------------|
| `space.xs` | 4 |
| `space.sm` | 8 |
| `space.md` | 12 |
| `space.lg` | 16 |
| `space.xl` | 24 |
| `space.xxl` | 32 |

### 2.4 Typography

| Key | Type | Meaning |
|-----|------|---------|
| `font.ui.family` | string | UI font family name (matches embedded font choice) |
| `font.ui.size_sm` | u32 | Small UI size (px) |
| `font.ui.size_md` | u32 | Default |
| `font.ui.size_lg` | u32 | Large |

### 2.5 Motion (`unsigned` ms)

| Key | Typical |
|-----|---------|
| `duration.fast` | 150 |
| `duration.normal` | 250 |
| `duration.slow` | 400 |

### 2.6 Shadow (placeholder ARGB tints)

Used until a real blur stack exists. Values are **tint** overlays (often low alpha).

| Key |
|-----|
| `shadow.elevation_0` |
| `shadow.elevation_1` |
| `shadow.elevation_2` |
| `shadow.elevation_3` |

---

## 3. macOS Dark — default ARGB (`AA = FF`)

| Key | ARGB |
|-----|------|
| `color.bg.base` | `0xFF1E1E1E` |
| `color.bg.surface` | `0xFF2C2C2C` |
| `color.bg.surface_elevated` | `0xFF3A3A3A` |
| `color.bg.surface_hover` | `0xFF333333` |
| `color.bg.surface_pressed` | `0xFF2A2A2A` |
| `color.bg.surface_selected` | `0xFF2D3D52` |
| `color.bg.surface_disabled` | `0xFF252528` |
| `color.border.subtle` | `0xFF424242` |
| `color.border.default` | `0xFF545458` |
| `color.border.strong` | `0xFF6E6E73` |
| `color.text.primary` | `0xFFF5F5F7` |
| `color.text.secondary` | `0xFFA1A1A6` |
| `color.text.tertiary` | `0xFF6E6E73` |
| `color.text.disabled` | `0xFF636366` |
| `color.accent.default` | `0xFF0A84FF` |
| `color.accent.hover` | `0xFF409CFF` |
| `color.accent.pressed` | `0xFF0060DF` |
| `color.semantic.success` | `0xFF32D74B` |
| `color.semantic.warning` | `0xFFFFD60A` |
| `color.semantic.error` | `0xFFFF453A` |
| `color.semantic.info` | `0xFF64D2FF` |
| `color.focus.ring` | `0xFF0A84FF` |

---

## 4. macOS Light — reference ARGB (for §3d / future `appearance`)

| Key | ARGB |
|-----|------|
| `color.bg.base` | `0xFFF5F5F7` |
| `color.bg.surface` | `0xFFFFFFFF` |
| `color.bg.surface_elevated` | `0xFFFFFFFF` |
| `color.border.subtle` | `0xFFD1D1D6` |
| `color.border.default` | `0xFFC6C6C8` |
| `color.text.primary` | `0xFF1D1D1F` |
| `color.text.secondary` | `0xFF6E6E73` |
| `color.text.tertiary` | `0xFFAEAEB2` |
| `color.accent.default` | `0xFF007AFF` |
| `color.accent.hover` | `0xFF0077ED` |
| `color.accent.pressed` | `0xFF006ADB` |
| `color.semantic.success` | `0xFF34C759` |
| `color.semantic.warning` | `0xFFFF9500` |
| `color.semantic.error` | `0xFFFF3B30` |
| `color.focus.ring` | `0xFF007AFF` |

(State / shadow / spacing match Dark keys where not listed; override in theme file later.)

---

## 5. Contrast targets (manual / future automatic)

- **Body text**: `color.text.primary` on `color.bg.base` or `color.bg.surface` ≥ **4.5:1**.
- **Large UI** (≥ 18 px equivalent): ≥ **3:1** for `text.secondary` on `bg.surface`.
- **`color.focus.ring`** on adjacent `bg.*` ≥ **3:1**.

---

## 6. Kernel API (`kernel/src/ui/ui_theme.h`)

| Function | Purpose |
|----------|---------|
| `ui_theme_init(void)` | After VFS + initrd mount: load `/etc/ui/theme.toml` (or `theme.json`), else compiled **Dark** baseline. |
| `ui_theme_get_u32(key)` | Colors, shadows, font sizes as u32. |
| `ui_theme_get_radius_dp(key)` | Radius tokens; unknown → `-1`. |
| `ui_theme_get_space_dp(key)` | Spacing; unknown → `0`. |
| `ui_theme_get_duration_ms(key)` | Durations; unknown → `0`. |
| `ui_theme_get_str(key)` | e.g. `font.ui.family`; unknown → `NULL`. |
| `ui_theme_reload(void)` | Re-read theme file, re-merge, invoke change callback (§3a.6). |
| `ui_theme_subscribe_changed(cb)` | Register `void (*cb)(void)` for reload (e.g. compositor full damage + desktop chrome). |
| `ui_theme_serial_poll(void)` | Drain COM1; line **`theme reload`** triggers `ui_theme_reload()`. |

Unknown keys: getters return **0 / -1 / NULL**; first few unknown keys per boot/reload emit one **`kprintf`** each (capped).

---

## 7. `theme.toml` / `theme.json` (subset, §3a.3)

**Location:** `/etc/ui/theme.toml` preferred, else `/etc/ui/theme.json` (initrd).

**TOML:** `#` line comments; `[meta]`, `[appearance]`, `[color]`, `[radius]`, `[space]`, `[duration]`, `[shadow]`, `[font]`. Under `[color]`, keys like `bg.base = #1E1E1E` map to `color.bg.base`. Values: `#RGB`, `#RRGGBB`, `0xAARRGGBB`, decimal integers, or quoted strings (e.g. `font.ui.family`). **`[appearance]`** `mode = "dark"` \| `"light"` selects the compiled **Dark** vs **Light** palette (§3a.2) before per-key merge.

**JSON:** Single `{ ... }` object; flat keys such as `"color.bg.base":"#F5F5F7"`; `"mode":"light"` or `"appearance":"light"` selects the Light palette before merge.

**Order:** baseline (Dark or full Light table) → shallow merge of known keys only.
