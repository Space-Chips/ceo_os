# Apple Human Interface Guidelines (HIG): Detailed Design Deep Dive

This detailed guide expands on the Apple Human Interface Guidelines, focusing on precise values, layout systems, typography scales, color systems, and hierarchy patterns to help you build "pixel-perfect" iOS applications.

---

## 1. Layout & Spacing System
Apple's layout philosophy relies on a mathematically consistent, point-based system.

### The 8pt Grid System
While not strictly enforced by the OS, an **8-point grid** is the de facto standard for professional iOS design.
- **Base Unit:** 8pt.
- **Micro-spacing:** 4pt (for tight groupings).
- **Macro-spacing:** 16pt, 24pt, 32pt, 40pt, 48pt...

### Standard Dimensions & Padding
| Element | Recommended Dimension/Value | Notes |
| :--- | :--- | :--- |
| **Minimum Touch Target** | **44 x 44pt** | Critical for usability. Buttons can be visually smaller but must have a 44pt hit area. |
| **Standard Margin** | **16pt** | The standard distance from the left and right edges of the screen for non-full-width content. |
| **Card Padding** | **16pt** | Standard internal padding for cards or grouped table views. |
| **Container Padding** | **16pt (Top/Bottom)** | Typical breathing room inside a section container. |
| **List Row Height** | **44pt (Small)** | Standard simple list item. |
| **List Row Height** | **60pt+ (Medium)** | List item with subtitle. |
| **Corner Radius** | **10pt - 22pt** | Varies by element size. Buttons often use ~12-14pt. Cards often match the device curve (approx 39-48pt for screen corners, scaled down for internal elements). |

### Safe Areas
- **Top Safe Area:** Typically **44pt - 47pt** (depending on device, e.g., Dynamic Island).
- **Bottom Safe Area:** **34pt**.
- **Role:** Never place interactive controls in these areas (behind the home indicator or status bar). Backgrounds should bleed into these areas, but content must stop.

---

## 2. Typography: The San Francisco (SF) Pro System
iOS uses **SF Pro** as the system font. It is optimized for legibility at all sizes.

### Font Variants
1.  **SF Pro Text:** Sizes **< 20pt**. Tracks out (wider letter spacing) automatically for legibility.
2.  **SF Pro Display:** Sizes **≥ 20pt**. Tracks tight (narrower) for cleaner headlines.
3.  **SF Pro Rounded:** Friendly, soft alternative. Matches weights of standard SF Pro.

### Dynamic Type Scale (Default "Large" Setting)
Use these semantic styles (SwiftUI/UIKit text styles) instead of hardcoded values to support accessibility scaling automatically.

| Style | Weight | Size (pt) | Leading (Line Height) | Use Case |
| :--- | :--- | :--- | :--- | :--- |
| **Large Title** | Regular / Bold | **34pt** | 41pt | Main page headings (collapsible). |
| **Title 1** | Regular | **28pt** | 34pt | Primary page headers. |
| **Title 2** | Regular | **22pt** | 28pt | Section headers. |
| **Title 3** | Regular | **20pt** | 25pt | Subsection headers. |
| **Headline** | Semibold | **17pt** | 22pt | Bolded text to distinguish from body. |
| **Body** | Regular | **17pt** | 22pt | Primary content text. |
| **Callout** | Regular | **16pt** | 21pt | Highlighted info. |
| **Subhead** | Regular | **15pt** | 20pt | Secondary descriptions. |
| **Footnote** | Regular | **13pt** | 18pt | Disclaimers, timestamps. |
| **Caption 1** | Regular | **12pt** | 16pt | Image captions. |
| **Caption 2** | Regular | **11pt** | 13pt | Smallest legible metadata. |

*Note: Minimum legible size is generally **11pt**.*

---

## 3. Color System & UI
Apple's color system is **semantic** and **adaptive**.

### Semantic Colors
Do not use "White" or "Black". Use semantic names that adapt to Dark Mode automatically.
- **`systemBackground`**: Pure White (Light) / Pure Black (Dark).
- **`secondarySystemBackground`**: Light Gray (Light) / Dark Gray (Dark). Used for grouped table views or cards.
- **`label`**: Black (Light) / White (Dark). Primary text.
- **`secondaryLabel`**: ~60% opacity. Subtitles.
- **`tertiaryLabel`**: ~30% opacity. Placeholders, disabled text.
- **`separator`**: Thin lines between list items.

### System Tints
Standard colors (`systemBlue`, `systemRed`, `systemGreen`) are tuned for legibility in both modes.
- **Light Mode Blue:** `#007AFF`
- **Dark Mode Blue:** `#0A84FF` (Slightly lighter/vibrant to pop against dark backgrounds)

### UI Materials (Blur / Translucency)
iOS relies heavily on **UIBlurEffect** materials to create depth ("z-axis").
- **Ultra Thin Material:** Very subtle.
- **Thin / Regular / Thick / Chrome Material:** Increasing levels of opacity.
- **Usage:** Sidebars, tab bars, navigation bars, and modals often use these materials so background content "peeks" through, maintaining context.

---

## 4. Visual Hierarchy & Patterns
Hierarchy guides the eye.

### Structuring Content
1.  **Position:** Top-left is primary.
2.  **Size:** Large Title > Title 2 > Body.
3.  **Weight:** Bold/Semibold invites attention; Regular/Light recedes.
4.  **Color:** `label` (Primary) vs `secondaryLabel` (Secondary). `systemBlue` (Interactive) vs. Gray (Static).

### Navigation Patterns
1.  **Flat (Tab Bar):**
    - Best for top-level, independent sections (3-5 tabs).
    - Persistent at the bottom.
2.  **Hierarchical (Navigation Stack):**
    - Drill-down pattern (List -> Detail).
    - Uses "Back" buttons top-left.
3.  **Modal (Sheets):**
    - Flows that require a specific task completion or decision.
    - **Page Sheet:** Covers mostly full screen but leaves top peeking (iOS 13+ card style).
    - **Form Sheet:** Smaller centered modal (iPad).
    - **Action Sheet:** Slide up from bottom for a choice (Delete, Save, Cancel).

### Common UI Patterns
- **Grouped Table View:**
    - A very common iOS pattern.
    - Gray background (`secondarySystemBackground`).
    - White cells (`systemBackground`) with 16pt corner radius.
    - Sections separated by whitespace and headers.
- **Edit Mode:**
    - "Edit" button top-right.
    - Lists enter a state to delete (red minus) or reorder (hamburger handle).
- **Search:**
    - Search bar typically lives inside the Navigation Bar.
    - Can be "Always Visible" or "Scroll to Reveal".

---

## 5. Summary Checklist for "Good" iOS Design
- [ ] Are elements aligned to an 8pt grid?
- [ ] Do buttons have a 44x44pt hit area?
- [ ] Is text using Dynamic Type styles (Body, Headline) instead of fixed sizes?
- [ ] Does the app support Dark Mode using semantic colors (`systemBackground`, `label`)?
- [ ] Are margins at least 16pt?
- [ ] Is the Safe Area respected (no content clipped by notches)?
- [ ] Does the app usage haptics (briefly) on significant actions?
