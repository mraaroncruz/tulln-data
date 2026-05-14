---
name: Civic Transparency Framework
colors:
  surface: '#f8f9ff'
  surface-dim: '#cbdbf5'
  surface-bright: '#f8f9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#eff4ff'
  surface-container: '#e5eeff'
  surface-container-high: '#dce9ff'
  surface-container-highest: '#d3e4fe'
  on-surface: '#0b1c30'
  on-surface-variant: '#414844'
  inverse-surface: '#213145'
  inverse-on-surface: '#eaf1ff'
  outline: '#717973'
  outline-variant: '#c1c8c2'
  surface-tint: '#3f6653'
  primary: '#012d1d'
  on-primary: '#ffffff'
  primary-container: '#1b4332'
  on-primary-container: '#86af99'
  inverse-primary: '#a5d0b9'
  secondary: '#2c694e'
  on-secondary: '#ffffff'
  secondary-container: '#aeeecb'
  on-secondary-container: '#316e52'
  tertiary: '#401b1b'
  on-tertiary: '#ffffff'
  tertiary-container: '#5a302f'
  on-tertiary-container: '#d29895'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#c1ecd4'
  primary-fixed-dim: '#a5d0b9'
  on-primary-fixed: '#002114'
  on-primary-fixed-variant: '#274e3d'
  secondary-fixed: '#b1f0ce'
  secondary-fixed-dim: '#95d4b3'
  on-secondary-fixed: '#002114'
  on-secondary-fixed-variant: '#0e5138'
  tertiary-fixed: '#ffdad8'
  tertiary-fixed-dim: '#f5b7b4'
  on-tertiary-fixed: '#331111'
  on-tertiary-fixed-variant: '#673a39'
  background: '#f8f9ff'
  on-background: '#0b1c30'
  surface-variant: '#d3e4fe'
  surface-base: '#F8FAFC'
  surface-subtle: '#F1F5F9'
  grade-a: '#2D6A4F'
  grade-b: '#74C365'
  grade-c: '#E9C46A'
  grade-d: '#F4A261'
  grade-e: '#BC4749'
  treemap-high: '#1B4332'
  treemap-mid: '#40916C'
  treemap-low: '#95D5B2'
typography:
  display-lg:
    fontFamily: Inter
    fontSize: 40px
    fontWeight: '700'
    lineHeight: 48px
    letterSpacing: -0.02em
  display-lg-mobile:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  body-lg:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
  body-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-sm:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  data-label:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 16px
  data-value:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '500'
    lineHeight: 24px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 16px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 32px
  xl: 48px
  container-max: 1280px
  gutter: 24px
---

## Brand & Style
The design system is rooted in the principles of civic accountability, clarity, and administrative confidence. It moves away from the promotional "city marketing" aesthetic toward a **Corporate / Modern** data-visualization style that prioritizes objectivity and readability.

The visual narrative is "Information as Infrastructure." This is achieved through a structured, systematic approach to layout, a restrained but authoritative color palette, and high-precision typography. The emotional goal is to provide Austrian citizens and administrators with a sense of stability and trustworthy transparency.

Key stylistic markers:
- **Calm & Honest:** No aggressive gradients or high-energy animations.
- **Data-First:** Visual hierarchy is dictated by data importance, not marketing goals.
- **Administrative Precision:** Every element feels intentional, aligned, and grounded.

## Colors
This design system utilizes a "Forest and Stone" palette to convey authority and stability. The **Forest Green (#1B4332)** serves as the primary brand anchor, used for headers, primary actions, and navigational landmarks. 

The background strategy relies on **Slate and Stone neutrals**, providing a clean, non-distracting canvas for complex data. 

**Grade Chips (A-E):** These colors are calibrated for "Honest Assessment." They avoid neon or vibrating saturations to maintain a professional tone even when indicating "Serious Red" performance levels.

**Data Visualization:** Treemaps and charts should primarily use monochromatic scales of the Brand Forest Green to maintain a unified identity, reserving the Grade hues specifically for performance-based indicators.

## Typography
The system uses **Inter** exclusively to ensure a systematic and utilitarian feel. 

**Tabular Figures (CRITICAL):** For all numeric data, currency (Euros), and ratios, the `font-variant-numeric: tabular-nums` or `font-feature-settings: 'tnum'` property must be enabled. This ensures that columns of numbers align vertically, which is essential for scanning financial reports and data tables.

**Hierarchies:**
- **Display Weights:** Reserved for major dashboard sections and key metric totals.
- **Medium/Regular Weights:** Used for descriptive text and administrative context.
- **Labels:** Small caps or slightly tracked-out labels can be used for secondary metadata in data visualizations.

## Layout & Spacing
The layout follows a **Fixed-Fluid hybrid** model. On desktop, content is contained within a 1280px max-width container to prevent line-lengths from becoming unreadable. 

- **Grid:** A 12-column grid system is used for dashboard layouts. 
- **The 16px Rule:** All spacing—gutters, margins, and padding—must be multiples of the 16px base unit. 
- **Data Density:** While whitespace should be "generous" to avoid visual clutter, data tables may use a compact 8px vertical padding to ensure high information density without sacrificing clarity.
- **Responsive Behavior:** On mobile devices, the 24px side margins reduce to 16px, and all 12-column stacks collapse into a single column.

## Elevation & Depth
This design system uses **Tonal Layering** supplemented by soft, functional shadows. 

- **Surface Levels:** The lowest level is the "Ground" (#F8FAFC). Interactive cards and data containers sit on the "Surface" level (#FFFFFF).
- **Shadows:** Shadows are highly diffused and low-opacity (alpha < 0.08). They are used not to simulate physical height, but to subtly separate data modules from the background.
- **Outlines:** A 1px border (#E2E8F0) is used on all cards to provide crisp definition, ensuring that the "softness" of the shadow doesn't compromise the professional, administrative look.

## Shapes
The shape language is "Subtly Organic." 

- **Cards & Primary Modules:** Use a **12px (0.75rem)** corner radius. This softens the technical nature of the data without appearing playful.
- **Interactive Elements:** Buttons and input fields use a **8px (0.5rem)** radius for a more precise, focused feel.
- **Grade Chips:** Small status indicators use a fully rounded "Pill" shape to distinguish them from larger layout blocks.

## Components
- **Cards:** The central building block. Features 12px corners, a 1px slate outline, and a soft shadow. Padding inside cards should be at least 24px (1.5x base unit).
- **Buttons:** Primary buttons use the Forest Green background with white text. Secondary buttons use a slate-600 outline. Labels are always in Sentence Case.
- **Grade Chips:** These small badges display a letter (A-E) alongside its specific hue. They use `Inter Bold` for the letter to ensure legibility at small sizes.
- **Input Fields:** Clean, minimal styling with 1px borders. Focus states use a 2px Forest Green ring.
- **Data Tables:** Headers are pinned, using a subtle Slate-100 background. Rows should have a hover state (#F1F5F9) to assist with horizontal scanning.
- **Icons:** Use **Heroicons (Outline)**. Icons should be used sparingly—only when they provide functional clarity (e.g., download, search, filter).
- **Language:** All UI copy must be in German, using plain, factual language (Beamtendeutsch avoided, but maintaining professional terminology).