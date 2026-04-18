# High-End Dark Mode Design System

## 1. Overview & Creative North Star: "The Digital Curator"
This design system is built for an elevated link management experience, moving away from the cluttered "bookmark folder" aesthetic toward a sophisticated, editorial-grade repository. 

**The Creative North Star: The Digital Curator.** 
The interface should feel like a private gallery or a premium obsidian archive. We achieve this through "Atmospheric Depth"—using shifting tones of ink and charcoal rather than rigid lines. By embracing intentional asymmetry and generous negative space, we transform a utility app into a focused, high-end sanctuary for information. The goal is to make the user feel as though they are not just "saving links," but "curating knowledge."

---

## 2. Colors: Atmospheric Tones
The palette is rooted in deep blacks and muted charcoals, punctuated by a sophisticated "Primary Blue" that feels technological yet calm.

### Core Tones
- **Background (`#0e0e0e`):** The base of the canvas. Deep, immersive, and absolute.
- **Surface & Containers:** 
  - `surface_container_low` (`#131313`): For subtle sectioning.
  - `surface_container_highest` (`#252626`): For high-impact interactive elements like the Search Bar.
- **Primary (`#004883`):** An airy, luminous blue used for highlights and critical actions.

### The "No-Line" Rule
Traditional 1px solid borders are strictly prohibited for sectioning. Structural boundaries must be defined solely through background color shifts. A list card should not have a border; it should simply exist as a `surface_container_low` block resting on a `surface` background.

### Surface Hierarchy & Nesting
Treat the UI as stacked sheets of glass. 
- **The Base:** Global background is `surface`.
- **The Group:** Sections (like a link category) use `surface_container_low`.
- **The Detail:** Individual items or search inputs (as seen in the reference image) use `surface_container_highest` to pull them toward the user.

### The "Glass & Gradient" Rule
For floating elements (Modals, Overlays, Floating Action Buttons), use semi-transparent `surface_variant` with a 20px Backdrop Blur. For main CTAs, apply a subtle linear gradient from `primary` to `primary_container` to add a sense of "physical light" to the button.

---

## 3. Typography: Editorial Precision
The system utilizes a dual-font strategy to balance character with readability.

- **Display & Headlines (Manrope):** A modern, geometric sans-serif with a technical edge.
  - **Headline-LG (`2rem`):** Used for gallery titles or folder names to establish an authoritative hierarchy.
- **Body & Labels (Inter):** The industry standard for high-legibility interface text.
  - **Body-MD (`0.875rem`):** For link descriptions and metadata.
  - **Label-SM (`0.6875rem`):** Used for tags and timestamps, set in `on_surface_variant` to keep the hierarchy quiet.

*Note: Use `title-lg` for link titles to ensure they feel substantial and clickable.*

---

## 4. Elevation & Depth: Tonal Layering
In "The Digital Curator," we replace shadows with light.

- **The Layering Principle:** Depth is achieved by "stacking." A search bar (`surface_container_highest`) is "closer" to the user because it is lighter than the background (`surface`). No shadow is needed for this basic relationship.
- **Ambient Shadows:** For floating menus, use a 40px blur, 10% opacity shadow tinted with `primary_dim`. This creates a "glow" effect rather than a "drop shadow," mimicking the way light behaves in a dark room.
- **The "Ghost Border" Fallback:** If a container requires further definition (e.g., a card against a similar background), use the `outline_variant` token at **15% opacity**. It should be felt, not seen.
- **Reference Image Implementation:** Notice how the search bar in the reference sits comfortably in the top header. In this system, that bar should utilize `roundedness.full` and `surface_container_highest` to create a tactile "cutout" look.

---

## 5. Components: Minimalist Primitives

### Buttons
- **Primary:** Gradient from `primary` to `primary_container`. Text in `on_primary`. Shape: `DEFAULT (1rem)`.
- **Secondary:** Surface-only. Background: `secondary_container`. Text: `on_secondary_container`.
- **Tertiary:** Ghost style. No background. `on_surface_variant` text. High-contrast only on hover.

### Link Cards
- **Structure:** No borders. Use `surface_container_low`. 
- **Spacing:** `xl (3rem)` padding between the edge of the screen and the content to create an editorial feel.
- **Interaction:** On hover, shift background to `surface_container_high`.

### Search Bar (Reference Pattern)
- Follow the reference image's layout: `roundedness.full`, `surface_container_highest` background.
- Typography: Use `body-md` for placeholder text in `on_surface_variant`.
- Iconography: Use thin-stroke (1.5px) icons in `on_surface_variant`.

### Chips & Tags
- Use `tertiary_container` with `on_tertiary_container` text.
- Shape: `sm (0.5rem)` for a modern, slightly squared-off aesthetic.

---

## 6. Do’s and Don’ts

### Do:
- **Do** use negative space as a functional element. Grouping items through proximity is cleaner than using boxes.
- **Do** use `primary_dim` for icons to give them a subtle "lit" quality against the dark background.
- **Do** ensure all interactive elements have at least a `md (1.5rem)` corner radius to maintain a friendly, high-end feel.

### Don’t:
- **Don’t** use `#000000` (Pure Black) for anything other than `surface_container_lowest`. It creates "black smear" on OLED screens and feels too heavy.
- **Don’t** use dividers or lines. If you feel the need to separate two items, add more vertical white space or a subtle tone shift.
- **Don’t** use high-contrast white (`#FFFFFF`) for body text. Use `on_surface` (`#e7e5e5`) to reduce eye strain in dark mode.