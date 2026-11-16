---
name: Culinary Contrast
colors:
  surface: '#faf9fd'
  surface-dim: '#dbd9dd'
  surface-bright: '#faf9fd'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f5f3f7'
  surface-container: '#efedf1'
  surface-container-high: '#e9e7ec'
  surface-container-highest: '#e3e2e6'
  on-surface: '#1b1b1f'
  on-surface-variant: '#5a4042'
  inverse-surface: '#2f3034'
  inverse-on-surface: '#f2f0f4'
  outline: '#8e6f71'
  outline-variant: '#e2bec0'
  surface-tint: '#ba1340'
  primary: '#b60e3d'
  on-primary: '#ffffff'
  primary-container: '#da3054'
  on-primary-container: '#fffbff'
  inverse-primary: '#ffb2b8'
  secondary: '#5e5e65'
  on-secondary: '#ffffff'
  secondary-container: '#e4e1ea'
  on-secondary-container: '#64636b'
  tertiary: '#8b4c11'
  on-tertiary: '#ffffff'
  tertiary-container: '#a96428'
  on-tertiary-container: '#fffbff'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#ffdadb'
  primary-fixed-dim: '#ffb2b8'
  on-primary-fixed: '#40000f'
  on-primary-fixed-variant: '#91002d'
  secondary-fixed: '#e4e1ea'
  secondary-fixed-dim: '#c8c5cd'
  on-secondary-fixed: '#1b1b21'
  on-secondary-fixed-variant: '#47464d'
  tertiary-fixed: '#ffdcc4'
  tertiary-fixed-dim: '#ffb780'
  on-tertiary-fixed: '#2f1400'
  on-tertiary-fixed-variant: '#6f3800'
  background: '#faf9fd'
  on-background: '#1b1b1f'
  surface-variant: '#e3e2e6'
typography:
  headline-xl:
    fontFamily: Plus Jakarta Sans
    fontSize: 32px
    fontWeight: '800'
    lineHeight: 40px
    letterSpacing: -0.03em
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 20px
    fontWeight: '700'
    lineHeight: 28px
    letterSpacing: -0.01em
  headline-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '700'
    lineHeight: 22px
  body-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '500'
    lineHeight: 24px
  body-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 20px
  body-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
  label-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 18px
  label-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
  label-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 10px
    fontWeight: '600'
    lineHeight: 14px
    letterSpacing: 0.02em
rounded:
  sm: 0.5rem
  DEFAULT: 1rem
  md: 1.5rem
  lg: 2rem
  xl: 3rem
  full: 9999px
spacing:
  gutter: 1rem
  margin: 1.25rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
---

## Brand & Style

This design system embodies an editorial, high-contrast modern culinary aesthetic. The core visual tension is established between an expansive, clean, airy canvas and rich, deeply saturated slate recipe cards that make culinary photography pop like framed gallery exhibits.

The experience evokes culinary passion, curated discovery, and effortless creation. Designed for home gourmets, culinary creators, and modern food enthusiasts, the interface pairs crisp geometric structure with playful tactile moments.

### Visual Style
- **High-Contrast Editorial Minimalism:** Pure light canvases with bold, deep obsidian cards creating focal anchors.
- **Vibrant Accent Energy:** Focused hits of energetic coral-ruby drive micro-interactions, favorites, ratings, and primary creation flows.
- **Gallery-Grade Framing:** Food photography is isolated within circular plates and rounded windows set against dark surfaces to highlight texture, warmth, and color.

## Colors

The palette establishes an inverted card-on-canvas hierarchy: an open, luminous base supporting deep midnight surfaces.

### Palette Architecture
- **Primary (`#FF4D6D`):** The signature vibrant coral-ruby used for heart toggles, star ratings, primary action triggers, and active bottom navigation states.
- **Secondary (`#1E1E24`):** Deep charcoal slate reserved for recipe cards, overlay panels, and rich contrast containers.
- **Tertiary (`#F4A261`):** Warm amber used sparingly for secondary tags, prep warnings, and secondary badge ratings.
- **Neutral Base (`#121316`):** Deepest onyx for high-contrast primary text on light canvases.
- **Canvas Neutrals:** `#FFFFFF` (pure surface) with an underlying app scaffold tint of `#F8F9FA`. Card interior subtle strokes use `rgba(255, 255, 255, 0.14)`.

## Typography

Typography relies entirely on **Plus Jakarta Sans** for its friendly geometry, open apertures, and modern editorial presence.

- **Headlines:** Use heavy weights (`700` and `800`) with snug letter spacing (`-0.02em` to `-0.03em`) for section intros such as "Recomended for You" and "Categories".
- **Card Titles:** In dark cards, titles are rendered in clean white (`#FFFFFF`) with medium-bold weights to maintain legibility against dark slate backgrounds.
- **Metadata & Subtitles:** Chef attributions and prep durations use softer tinting (`#A0A3BD` on dark surfaces; `#6C757D` on white surfaces) to maintain clean visual hierarchy.

## Layout & Spacing

The layout is built for fluid touch ergonomics on mobile viewports with horizontal carousel snapping and clean vertical rhythm.

### Grid & Margins
- **Canvas Margins:** Screen edge safe area margin is set at `1.25rem` (20px) on mobile viewports.
- **Card Carousel Gutters:** `1rem` (16px) space between horizontal scrolling cards, maintaining visible peek cues for adjacent cards.
- **Component Padding Scale:**
  - `space-xs` (4px): Micro gaps between icons and rating counts.
  - `space-sm` (8px): Inner padding of pill tags and metadata chips.
  - `space-md` (16px): Internal recipe card padding surrounding titles and tags.
  - `space-lg` (24px): Vertical spacing between distinct screen sections.
  - `space-xl` (32px): Separation between carousel blocks and bottom navigation safe areas.

## Elevation & Depth

Visual depth is achieved through color contrast and soft ambient drop shadows rather than heavy structural borders.

### Surface Tiers
- **Tier 0 (Canvas Base):** Flat `#FFFFFF` or `#F8F9FA` with zero elevation.
- **Tier 1 (Dark Slate Recipe Cards):** `#1E1E24` card background elevated by an ambient shadow (`0px 10px 24px rgba(30, 30, 36, 0.12)`) and an optional ultra-fine hairline outline (`rgba(255, 255, 255, 0.08)`) to preserve card boundaries.
- **Tier 2 (Floating Floating Action / Hearts):** Translucent dark or tinted roundel badges (`rgba(0, 0, 0, 0.45)`) floating above dish photography with a soft backdrop blur (`8px`).
- **Tier 3 (Bottom Navigation Bar):** Pure white container elevated with a directional negative-Y shadow (`0px -6px 20px rgba(0, 0, 0, 0.05)`).

## Shapes

The design system embraces generous, friendly curvature that softens the high contrast between dark cards and the light canvas.

- **Recipe Cards:** `rounded-3xl` (24px to 28px) corner curvature on both feature cards and compact grid tiles.
- **Pill Tags:** Fully rounded pill radius (`9999px`) for category markers and filter chips.
- **Dish Imagery:** Centered circular cutouts or rounded framed insets (`rounded-full` or `rounded-2xl`) to evoke plates on restaurant surfaces.
- **Floating Buttons & Upload Trigger:** Rounded squares (`12px` to `16px`) for the primary creation button in the navigation dock.

## Components

### Buttons & Action Links
- **Primary CTA:** Pill or rounded rectangle with `#FF4D6D` background, white label text, and subtle hover/active scale-down (`active:scale-95`).
- **Text Buttons / See All:** Semibold `body-md` in `#FF4D6D` placed inline with section headers.

### Recipe Cards
- **Dark Feature Cards:** Fixed aspect ratio or min-height cards featuring `#1E1E24` slate surface, top-pinned circular dish photo, top-right floating circular favorite button, pill tag ('Asian Food'), rating indicator (`★ 4.5` in `#FF4D6D`), bold dish title, and subtle chef name.
- **Selected Card Variant:** Subtle dual outline with glowing coral border (`2px solid #FF4D6D`) to indicate focus or active carousel selection.

### Tags & Chips
- **In-Card Category Tag:** Dark pill with crisp border (`1px solid rgba(255, 255, 255, 0.3)`), transparent background, and white text (`label-sm`).
- **Canvas Category Chips:** Soft light grey pills (`#F0F1F5`) on canvas switching to solid `#1E1E24` with white text when selected.

### Bottom Navigation Dock
- **Architecture:** Fixed bottom bar containing 5 evenly spaced destinations:
  1. *Home* (House icon; filled `#FF4D6D` when active)
  2. *Explore* (Compass outline)
  3. *Add / Upload* (Enclosed plus inside rounded square outline)
  4. *Favorites* (Heart outline)
  5. *Profile* (User outline)
- **Safe Area:** 16px bottom padding with standard home indicator inset.

### Input Fields & Upload Drag-Drop
- Minimalist rounded text fields with light canvas backgrounds (`#F4F5F8`), zero border or soft focus rings matching the primary ruby-coral hue.