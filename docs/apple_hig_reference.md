# Apple Human Interface Guidelines — Reference

Comprehensive reference for implementing iOS-native designs.
All values are in logical points (pt) unless otherwise noted.

---

## 1. Typography — SF Pro

### Font Family Rules
| Size Range | Family | Usage |
|---|---|---|
| ≤ 19pt | SF Pro Text | Body, captions, labels |
| ≥ 20pt | SF Pro Display | Titles, headings |
| Code / tabular | SF Mono | Monospaced content |

### iOS Type Scale (Dynamic Type defaults)
| Style | Size (pt) | Weight | Line Height | Tracking |
|---|---|---|---|---|
| Large Title | 34 | Bold (w700) | 41pt (1.21x) | 0.37 |
| Title 1 | 28 | Regular (w400) | 34pt (1.21x) | 0.36 |
| Title 2 | 22 | Regular (w400) | 28pt (1.27x) | 0.35 |
| Title 3 | 20 | Regular (w400) | 25pt (1.25x) | 0.38 |
| Headline | 17 | Semibold (w600) | 22pt (1.29x) | -0.41 |
| Body | 17 | Regular (w400) | 22pt (1.29x) | -0.41 |
| Callout | 16 | Regular (w400) | 21pt (1.31x) | -0.32 |
| Subheadline | 15 | Regular (w400) | 20pt (1.33x) | -0.24 |
| Footnote | 13 | Regular (w400) | 18pt (1.38x) | -0.08 |
| Caption 1 | 12 | Regular (w400) | 16pt (1.33x) | 0.0 |
| Caption 2 | 11 | Regular (w400) | 13pt (1.18x) | 0.07 |

### Weight Usage Guidelines
| Weight | When to Use |
|---|---|
| Regular (w400) | Body text, secondary content |
| Medium (w500) | Subtle emphasis, secondary headers |
| Semibold (w600) | Section headers, buttons, nav bar titles |
| Bold (w700) | Large titles, primary CTAs, strong emphasis |

### Rules
- Minimum text size: **11pt**
- Line height: **120–130%** for Text, **110–120%** for Display
- Avoid Ultralight/Thin/Light weights — poor legibility
- Support Dynamic Type for accessibility

---

## 2. Colors — Dark Mode System Palette

### Background Hierarchy
| Semantic Name | Dark Mode Hex | Usage |
|---|---|---|
| systemBackground | `#000000` | Primary app background |
| secondarySystemBackground | `#1C1C1E` | Grouped/elevated sections |
| tertiarySystemBackground | `#2C2C2E` | Nested groups, cards |
| systemGroupedBackground | `#000000` | Grouped table/list background |
| secondarySystemGroupedBackground | `#1C1C1E` | Grouped section cards |
| tertiarySystemGroupedBackground | `#3A3A3C` | Nested grouped content |

### Label Hierarchy
| Semantic Name | Dark Mode Hex | Opacity | Usage |
|---|---|---|---|
| label | `#FFFFFF` | 100% | Primary text |
| secondaryLabel | `#EBEBF5` | 60% | Secondary text |
| tertiaryLabel | `#EBEBF5` | 30% | Tertiary/placeholder text |
| quaternaryLabel | `#EBEBF5` | 18% | Disabled text |

### Separator Colors
| Semantic Name | Dark Mode Hex | Usage |
|---|---|---|
| separator | `#545458` at 65% opacity | Default dividers |
| opaqueSeparator | `#38383A` | Opaque dividers |

### System Accent Colors (Dark Mode)
| Color | Dark Hex | Usage |
|---|---|---|
| systemBlue | `#0A84FF` | Links, interactive elements, primary accent |
| systemGreen | `#30D158` | Success, completion |
| systemRed | `#FF453A` | Errors, destructive actions |
| systemOrange | `#FF9F0A` | Warnings, alerts |
| systemYellow | `#FFD60A` | Highlights, stars |
| systemPurple | `#BF5AF2` | Categories, branding |
| systemPink | `#FF375F` | Health, badges |
| systemTeal | `#40C8E0` | Info indicators |
| systemIndigo | `#5E5CE6` | Secondary accent |
| systemCyan | `#64D2FF` | Info, links |

### Fill Colors
| Semantic Name | Dark Mode | Usage |
|---|---|---|
| systemFill | `#7878805C` | Thin overlays on grouped content |
| secondarySystemFill | `#78788052` | Slightly thicker fills |
| tertiarySystemFill | `#7676803D` | Thicker fills, selected states |
| quaternarySystemFill | `#74748033` | Heaviest fills |

### Rules
- Use **semantic colors** — never hardcode hex values for system elements
- Ensure **4.5:1** minimum contrast ratio for text
- **7:1** for enhanced accessibility
- Accent color should be used **sparingly** — primarily for interactive elements
- Don't use color as the sole indicator of state

---

## 3. Layout & Spacing

### Screen Margins
| Context | Left/Right Margin |
|---|---|
| iPhone (all sizes) | **16pt** |
| iPhone (readableContentGuide) | **20pt** (for text-heavy) |
| iPad (compact) | **20pt** |
| iPad (regular) | Content width capped |

### Component Heights
| Component | Height |
|---|---|
| Status bar | 54px (notch devices) |
| Navigation bar (standard) | **44pt** |
| Navigation bar (large title) | **96pt** |
| Tab bar | **49pt** (83pt with safe area) |
| Search bar | **36pt** |
| Toolbar | **44pt** |
| Home indicator zone | **34pt** |

### Touch Targets
- Minimum tappable area: **44 × 44 pt**
- Applies to buttons, switches, checkboxes, list rows
- Padding around icons to meet 44pt if icon itself is smaller

### Spacing System
| Token | Value | Usage |
|---|---|---|
| Tight | **4pt** | Icon-to-label, inline elements |
| Standard | **8pt** | Between related items |
| Comfortable | **12pt** | Between list items |
| Section | **16pt** | Between content sections |
| Large | **20pt** | Major section breaks |
| Extra-large | **32pt** | Page-level separation |

### Card / Grouped Content
- Corner radius: **10pt** (standard), **13pt** (large)
- Internal padding: **16pt** horizontal, **11pt** vertical (list cells)
- Card-to-card gap: **8pt**

### List Cell Heights
| Cell Type | Minimum Height |
|---|---|
| Standard | **44pt** |
| Subtitle | **60pt** |
| Custom (multi-line) | **Auto** (min 44pt) |

### Rules
- Content within safe area insets — never clip behind notch/home indicator
- Respect `layoutMarginsGuide` for consistent padding
- Use **8pt grid** as base spacing unit
- Full-bleed images can extend to edges; text/controls must not

---

## 4. Navigation

### Tab Bar
- **Max 5 tabs** on iPhone
- Use **SF Symbols** — filled variant for active, outline for inactive
- Active tab tint: `systemBlue` or app accent
- Inactive tab tint: `secondaryLabel` equivalent (gray)
- Label font: **Caption 2** (10pt, medium weight)
- Tab bar is always visible — never hide it

### Navigation Bar
- Standard title: **17pt Semibold**, centered
- Large title: **34pt Bold**, left-aligned, collapses on scroll
- Back button on left, max 2 action buttons on right
- Translucent background with system blur
- Border: 0.5pt separator at bottom

### Rules
- Use tab bars for **flat** navigation (top-level sections)
- Use navigation bars for **hierarchical** content (push/pop)
- Keep navigation consistent — don't mix tab placement
- Large titles are preferred for top-level screens

---

## 5. Components

### Buttons
| Type | Usage | Height |
|---|---|---|
| Filled | Primary actions | 50pt (large), 34pt (standard) |
| Tinted | Secondary actions | Same |
| Gray | Neutral actions | Same |
| Plain/Link | Tertiary, inline actions | Text only |
- Corner radius: **12pt** (large), **8pt** (standard)
- Font: **Body** (17pt) for large, **Subheadline** (15pt) for standard
- Min width: action-dependent, full-width for forms

### Text Fields
- Height: **36pt** (standard), **44pt** (large)
- Corner radius: **10pt**
- Background: `tertiarySystemFill` or `secondarySystemBackground`
- Padding: **8pt** horizontal
- Placeholder color: `tertiaryLabel`
- Border: none (filled style) or 1pt `separator` color

### Switches
- Size: **51 × 31 pt** (fixed, system-provided)
- Active track: app accent or `systemGreen`
- Inactive track: system fill
- No custom styling — use system switch

### Cards (custom grouped content)
- Background: `secondarySystemGroupedBackground` (`#1C1C1E`)
- Corner radius: **10pt**
- Internal padding: **16pt**
- No visible border in dark mode (elevation = color differentiation)
- Shadow: none in dark mode

---

## 6. Core Principles Summary

1. **Clarity** — Legible text, clear icons, purposeful styling
2. **Deference** — UI supports content, not the other way around
3. **Depth** — Layers and translucency create hierarchy
4. **Consistency** — Same patterns everywhere, match system conventions
5. **Direct Manipulation** — Content responds to gestures naturally
6. **Feedback** — Every action has a visible response

---

## Quick Audit Checklist

- [ ] Background colors match system hierarchy (black → #1C1C1E → #2C2C2E)
- [ ] Text sizes follow Dynamic Type scale (34/28/22/20/17/15/13/12/11)
- [ ] Font weights match role (Bold for titles, Semibold for headers, Regular for body)
- [ ] Margins are 16pt on iPhone
- [ ] Touch targets ≥ 44pt
- [ ] Tab bar uses filled/outline SF Symbols with 10pt labels
- [ ] Cards use #1C1C1E background with 10pt radius
- [ ] No borders on cards in dark mode
- [ ] Spacing follows 8pt grid
- [ ] Accent color used sparingly (interactive elements only)
