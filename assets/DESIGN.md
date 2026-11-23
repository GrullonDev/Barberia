---
name: Premium Grooming Identity
colors:
  surface: '#121414'
  surface-dim: '#121414'
  surface-bright: '#38393a'
  surface-container-lowest: '#0c0f0f'
  surface-container-low: '#1a1c1c'
  surface-container: '#1e2020'
  surface-container-high: '#282a2b'
  surface-container-highest: '#333535'
  on-surface: '#e2e2e2'
  on-surface-variant: '#c4c7c7'
  inverse-surface: '#e2e2e2'
  inverse-on-surface: '#2f3131'
  outline: '#8e9192'
  outline-variant: '#444748'
  surface-tint: '#c8c6c5'
  primary: '#c8c6c5'
  on-primary: '#313030'
  primary-container: '#1a1a1a'
  on-primary-container: '#848282'
  inverse-primary: '#5f5e5e'
  secondary: '#e9c349'
  on-secondary: '#3c2f00'
  secondary-container: '#af8d11'
  on-secondary-container: '#342800'
  tertiary: '#dec1af'
  on-tertiary: '#3f2c20'
  tertiary-container: '#26170c'
  on-tertiary-container: '#977e6e'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#e5e2e1'
  primary-fixed-dim: '#c8c6c5'
  on-primary-fixed: '#1c1b1b'
  on-primary-fixed-variant: '#474746'
  secondary-fixed: '#ffe088'
  secondary-fixed-dim: '#e9c349'
  on-secondary-fixed: '#241a00'
  on-secondary-fixed-variant: '#574500'
  tertiary-fixed: '#fbddca'
  tertiary-fixed-dim: '#dec1af'
  on-tertiary-fixed: '#28180d'
  on-tertiary-fixed-variant: '#574335'
  background: '#121414'
  on-background: '#e2e2e2'
  surface-variant: '#333535'
typography:
  headline-lg:
    fontFamily: Playfair Display
    fontSize: 48px
    fontWeight: '700'
    lineHeight: '1.2'
    letterSpacing: -0.02em
  headline-lg-mobile:
    fontFamily: Playfair Display
    fontSize: 32px
    fontWeight: '700'
    lineHeight: '1.2'
  headline-md:
    fontFamily: Playfair Display
    fontSize: 32px
    fontWeight: '600'
    lineHeight: '1.3'
  headline-sm:
    fontFamily: Playfair Display
    fontSize: 24px
    fontWeight: '600'
    lineHeight: '1.4'
  body-lg:
    fontFamily: Hanken Grotesk
    fontSize: 18px
    fontWeight: '400'
    lineHeight: '1.6'
  body-md:
    fontFamily: Hanken Grotesk
    fontSize: 16px
    fontWeight: '400'
    lineHeight: '1.6'
  label-md:
    fontFamily: Hanken Grotesk
    fontSize: 14px
    fontWeight: '600'
    lineHeight: '1.2'
    letterSpacing: 0.05em
  label-sm:
    fontFamily: Hanken Grotesk
    fontSize: 12px
    fontWeight: '500'
    lineHeight: '1.2'
    letterSpacing: 0.03em
rounded:
  sm: 0.125rem
  DEFAULT: 0.25rem
  md: 0.375rem
  lg: 0.5rem
  xl: 0.75rem
  full: 9999px
spacing:
  base: 8px
  container-max: 1200px
  gutter: 24px
  margin-mobile: 16px
  margin-desktop: 48px
---

## Brand & Style
The brand personality is rooted in the tradition of the "Gentleman’s Lounge"—sophisticated, masculine, and timelessly professional. It evokes the sensory experience of a high-end barbershop: the scent of sandalwood, the weight of a steel razor, and the comfort of a leather chair.

The design style follows a **Modern Tactile** approach. It utilizes high-contrast surfaces and minimalist layouts, enriched by subtle textures like brushed metal and grain. The aesthetic prioritizes prestige and precision, ensuring the UI feels as curated as a master-class haircut.

## Colors
The palette is anchored in **Deep Charcoal (#1A1A1A)**, providing a moody, premium foundation that replaces traditional blacks for a softer, more cinematic feel. **Gold (#D4AF37)** is used sparingly as a high-prestige accent for calls to action, active states, and brand marks. 

**Off-white (#F5F5F5)** serves as the primary text color to ensure maximum readability against dark backgrounds without the harshness of pure white. **Dark Wood (#3D2B1F)** is reserved for subtle background layering and decorative dividers, adding warmth to the otherwise cool, metallic environment.

## Typography
The typography strategy contrasts the old world with the new. **Playfair Display** provides an editorial, high-contrast serif look for headings, suggesting authority and heritage. **Hanken Grotesk** is used for all functional UI elements, body copy, and labels to maintain a sharp, contemporary edge.

For labels and small headers, an increased letter spacing and uppercase transformation should be applied to evoke the look of luxury watch face inscriptions or premium product packaging.

## Layout & Spacing
This design system utilizes a **Fixed Grid** model for desktop to ensure an editorial, "lookbook" feel, centering the content at a maximum width of 1200px. The spacing rhythm is based on an 8px linear scale.

- **Desktop (1440px+):** 12-column grid, 24px gutters, 48px outside margins.
- **Tablet (768px - 1439px):** 8-column grid, 20px gutters, 32px outside margins.
- **Mobile (Under 767px):** 4-column fluid grid, 16px gutters, 16px outside margins.

Layouts should favor asymmetrical compositions and generous vertical breathing room (whitespace) to reinforce the premium brand positioning.

## Elevation & Depth
Depth is created through **Tonal Layering** and high-precision strokes rather than heavy shadows. 

- **Surface Level 0:** The primary background color (#1A1A1A).
- **Surface Level 1 (Cards/Modals):** A slightly lighter charcoal (#242424) with a 1px inner border in a "brushed metal" style (low-opacity white or gold).
- **Floating Elements:** Use a subtle, large-radius shadow with a #000000 at 40% opacity to lift elements off the surface without appearing "soft."
- **Accents:** Use a faint Gold outer glow (5-10px blur) for active states to simulate a metallic reflection.

## Shapes
The shape language is **Soft (Level 1)**. This ensures that while the design feels modern and accessible, it retains a masculine "sharpness." 

- Standard components (buttons, inputs) use a **4px (0.25rem)** corner radius.
- Larger containers and cards use an **8px (0.5rem)** radius.
- Decorative elements or specific "Selection" chips may use a sharp 0px radius to emphasize a "straight-edge" razor aesthetic where appropriate.

## Components
### Buttons
- **Primary:** Solid Gold (#D4AF37) with Charcoal text. High-contrast, rectangular with 4px radius.
- **Secondary:** Outlined Gold with Gold text. Used for less urgent actions.
- **Ghost:** Off-white text with no background, used for navigation.

### Cards (Service & Barber Profiles)
Cards feature a Level 1 surface. Service cards should include a subtle Dark Wood texture or a gradient overlay for imagery to ensure text readability. Use thin 1px Gold borders only for "Featured" or "Selected" states.

### Date Pickers
The date picker should be a custom, dark-themed component. Selected dates use the Gold background. The interface should feel like a high-end physical planner, using Playfair Display for month headers.

### Input Fields & Selects
Inputs use a "bottom-border only" or "low-opacity ghost" style. When focused, the bottom border transitions to Gold with a very subtle glow.

### Chips & Badges
Small, rectangular tags with 0px or 2px radius. Use Charcoal backgrounds with Gold text for "Premium" service indicators or "Expert" barber badges.