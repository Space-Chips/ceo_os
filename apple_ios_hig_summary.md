# Apple Human Interface Guidelines (HIG) for iOS - Comprehensive Summary

This document provides a comprehensive summary of Apple's Human Interface Guidelines for iOS, including the latest updates regarding Apple Intelligence and Generative AI (2024–2025).

---

## 1. Core Design Principles
These principles are the foundation of all iOS app designs.

- **Clarity:** Content is paramount. Text is legible at every size, icons are precise and lucid, and adornments are subtle and appropriate. Negative space, color, fonts, graphics, and interface elements highlight important content and convey interactivity.
- **Deference:** The interface should defer to the content. The UI serves the user’s content and interactions, avoiding overpowering them. It retreats when content is the focus (e.g., full-screen video).
- **Depth:** Visual layers and realistic motion impart vitality. Distinct visual layers help users understand the hierarchy.
- **Consistency:** Use system-provided interface elements, well-known icons, standard text styles, and uniform terminology to create a familiar experience.
- **Aesthetic Integrity:** The appearance of the app should match its function. Serious tasks need subtle, unobtrusive graphics; immersive games can use rich, captivating visuals.
- **Feedback:** Interactiveness requires acknowledgement. Users expect immediate, clear feedback for their actions (visual, auditory, or haptic).

---

## 2. Foundations
The building blocks of the iOS interface.

### Layout & Adaptivity
- **Safe Areas:** Ensure content isn't clipped by device corners, the notch/dynamic island, or the home indicator. Use the system-defined safe area layout guides.
- **Margins & Padding:** Use standard `8pt` (or `16pt` for margins) grid systems. The UI should "breathe" with ample whitespace.
- **Device Adaptability:** Apps must adapt seamlessly to different screen sizes (iPhone SE to Pro Max) and orientations (Portrait/Landscape) using Auto Layout.

### Color
- **System Colors:** Use semantic system colors (e.g., `systemBlue`, `label`, `systemBackground`) that automatically adapt to appearances.
- **Dark Mode:** All apps must support Dark Mode. Use dynamic colors that change effectively between Light and Dark interfaces.
- **Color Management:** Use P3 wide color gamuts for rich visuals where compatible.

### Typography
- **San Francisco (SF) Pro:** The system font for iOS. It is optimized for legibility.
- **Dynamic Type:** All text should scale according to user preference. Avoid fixed font sizes; use text styles (e.g., `.body`, `.headline`, `.largeTitle`).
- **Legibility:** Prioritize high contrast and clear hierarchy.

### Iconography & Graphics
- **SF Symbols:** Use Apple's library of over 5,000 vector icons that integrate seamlessly with San Francisco and support Dynamic Type and weights.
- **App Icons:** Must be simple, recognizable, and typically tested against different wallpapers.
- **Imagery:** Support high-resolution (`@2x`, `@3x`) assets.

---

## 3. Interface Essentials encompasses
The standard components used to build the UI.

### Bars
- **Navigation Bar:** Located at the top; implies hierarchy. Contains the title and navigation buttons (Back, Edit).
- **Tab Bar:** Located at the bottom; explicitly for switching between top-level sections of an app.
- **Toolbars:** Located at the bottom; contain actions relevant to the current screen context.
- **Search Bars:** Standardized input for filtering content.
- **Status Bar:** Displays system info (Battery, Time). Do not hide unless absolutely necessary (e.g., full-screen media).

### Views
- **Lists (Table Views):** The most common pattern for displaying scrolling data. Supports plain, grouped, and inset grouped styles.
- **Collections:** Grid-based or custom layouts for highly visual content.
- **Sheets:** Modal views that slide up from the bottom (half or full height) to safeguard context while offering a sub-task.
- **Popovers:** Used primarily on iPad (and occasionally iPhone menu equivalents) to show contextual info.
- **Alerts:** Critical notifications that interrupt user flow. Use sparingly.

### Controls
- **Buttons:** standard system buttons (filled, tinted, gray, plain) that support different prominence levels.
- **Pickers:** Wheels or lists for selecting dates, times, or options.
- **Sliders:** For granular selection within a range (e.g., volume, brightness).
- **Switches:** Binary On/Off toggles.
- **Segmented Controls:** Linear set of segments for mutually exclusive choices.
- **Context Menus:** Replaced 3D Touch; long-press interactions that reveal actions and previews.

---

## 4. User Interaction
How users communicate with the app.

- **Gestures:** Respect standard gestures (Tap, Swipe, Pinch, Pan). Avoid conflicting with system-wide gestures (like swiping up for Home).
- **Haptics:** Use the Taptic Engine to reinforce actions (e.g., success limits, failures, heavy impacts) but do not overuse.
- **Drag and Drop:** Support dragging content between apps or within the app (especially powerful on iPadOS).
- **Loading State:** Be honest about loading. Use activity indicators or progress bars. Skeleton screens are often preferred over blank screens.

---

## 5. Apple Intelligence & Generative AI (New 2024-2025)
Guidelines for integrating the latest AI capabilities.

### Writing Tools
- **Integration:** Apps should adopt standard `UITextView` and `NSTextView` interfaces to automatically inherit system Writing Tools (Proofread, Rewrite, Summarize).
- **Customization:** If building custom text editors, explicit adoption of the `WritingTools` API is required to allow users to invoke AI assistance.

### Generative Imagery
- **Image Playground:** If integrating image generation, use the system-provided sheets and experiences to ensure consistent user expectations.
- **Genmoji:** Support these as standard inline images within text fields. They behave like emojis but are generated images.
- **Attribution & Labeling:** AI-generated content must be clearly distinguishable or labeled if it simulates real-world events/people, to maintain trust (Deference/Clarity principles apply heavily here).

### Siri & App Intents
- **App Shortcuts:** Expose core app functionalities to Siri via App Intents.
- **Visual Intelligence:** Ensure your app's content is "readable" by the system so users can query onscreen content (e.g., "Summarize this email").

---

## 6. System Capabilities
Integrating with the deeper iOS ecosystem.

- **Widgets:** Small, glanceable views on the Home Screen. They must not provide full app interactivity but rather deep links and data snippets.
- **Live Activities:** Real-time updates on the Lock Screen and in the Dynamic Island (e.g., food delivery, sports scores). They require specific design constraints for the compact Island layout.
- **Notifications:** Must be timely and relevant. Grouped notifications help reduce clutter.
- **SharePlay:** enabling users to experience content together in real-time (watching, listening, playing).

---

## 7. Accessibility
Inclusive design is not optional on iOS.
- **VoiceOver:** All custom controls must have accessibility labels and hints.
- **Dynamic Type:** All text must scale.
- **Contrast:** Ensure a minimum 4.5:1 ratio for text.
- **Motion:** Respect "Reduce Motion" settings for users sensitive to parallax or zoom effects.
