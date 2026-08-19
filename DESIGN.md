# D20 Farm - Visual Design System

This document defines the visual tokens, layout rules, and animation contracts for the D20 idle dice game UI. All UI code must reference these tokens — no hardcoded values outside this file.

## Layout Tokens

| Element | Size | Position |
|---------|------|----------|
| Dice display box | 300×300 px | Center of screen (AnchorPoint 0.5,0.5) |
| Roll button | 200×60 px | Centered below dice box, 20 px gap |
| Coin counter | auto width × 32 px | Top-left, 16 px margin from edges |
| "+N" coin popup | auto width × 24 px | Spawns above dice box center, tweens up |
| Shop toggle icon | 40×40 px | Top-right, 16 px margin from edges |
| Shop panel | 320×400 px | Right side, vertically centered |

## Dice Display

### Scale Curve

Dice shrink as the owned count increases to keep the 300×300 box uncluttered.

| Dice count | Scale |
|------------|-------|
| 1 | 100 % |
| 2 | 88 % |
| 3 | 80 % |
| 5 | 60 % |
| 8 | 48 % |
| 10 | 40 % |

Formula: `scale = max(0.4, 1 - (count - 1) * 0.067)` clamped to [0.4, 1.0].

### Grid Layout

Dice are arranged in a grid inside the 300×300 box.

- Columns = `ceil(sqrt(count))`
- Rows = `ceil(count / columns)`
- Cell size = `300 / max(columns, rows)`
- Each die is centered inside its cell using the scale factor above.

### Animation: Roll Spin

- Property: `Rotation` 0 → 360
- Duration: 0.5 s
- Easing: `Enum.EasingStyle.Cubic`, `Enum.EasingDirection.Out`
- On completion: rotation reset to 0 (no cumulative drift)
- All dice spin simultaneously; no stagger

### Animation: Critical Glow (Natural 20)

- A glow `ImageLabel` is parented to each die
- Size: 120 % of parent (overflows by 10 % on each side)
- Color: `Color3.fromRGB(255, 215, 0)` (gold)
- Starting transparency: 0.5
- Duration: 1.0 s fade to transparency 1.0, then destroy
- No scale pulse — clean fade only

## Colors

### UI Palette

| Token | Value | Usage |
|-------|-------|-------|
| `gold` | `Color3.fromRGB(255, 215, 0)` | Accent, critical glow, "+N" popup text |
| `buttonDefault` | `Color3.fromRGB(50, 50, 50)` | Roll button background |
| `buttonHover` | `Color3.fromRGB(70, 70, 70)` | Roll button hover state |
| `buttonDisabled` | `Color3.fromRGB(30, 30, 30)` | Roll button during cooldown |
| `textPrimary` | `Color3.fromRGB(255, 255, 255)` | Coin count, die values |
| `textSecondary` | `Color3.fromRGB(180, 180, 180)` | Labels, descriptions |
| `panelBackground` | `Color3.fromRGB(20, 20, 20)` | Shop panel, overlays |
| `panelBorder` | `Color3.fromRGB(60, 60, 60)` | Panel stroke / border |

### Dice Tier Colors

Sourced from `Constants.DICE_TYPES`. Each die tint is applied as `ImageColor3` on the dice sprite.

| Tier | Name | Color |
|------|------|-------|
| 0 | Wooden D20 | `rgb(139, 90, 43)` |
| 1 | Stone D20 | `rgb(128, 128, 128)` |
| 2 | Iron D20 | `rgb(192, 192, 192)` |
| 3 | Gold D20 | `rgb(255, 215, 0)` |
| 4 | Emerald D20 | `rgb(80, 200, 120)` |
| 5 | Ruby D20 | `rgb(220, 50, 50)` |
| 6 | Diamond D20 | `rgb(180, 230, 255)` |
| 7 | Obsidian D20 | `rgb(30, 30, 40)` |
| 8 | Cosmic D20 | `rgb(100, 80, 200)` |
| 9 | Legendary D20 | `rgb(255, 170, 0)` |
| 10 | Mythic D20 | `rgb(255, 60, 120)` |

### Background

The background uses a subtle vertical gradient built from the average color of owned dice, blended with the base panel color. Start at owned-dice average color at 20 % opacity fading to `panelBackground` at 100 %.

## Typography

| Element | Size | Weight | Color |
|---------|------|--------|-------|
| Coin count | 24 px | Bold | `textPrimary` |
| "+N" popup | 18 px | Bold | `gold` |
| Dice tier label | 14 px | Regular | `textSecondary` |
| Shop item name | 16 px | SemiBold | `textPrimary` |
| Shop item price | 14 px | Regular | `gold` |
| Roll button label | 20 px | Bold | `textPrimary` |

Font stack: ` GothamMedium` (body), ` GothamBold` (headings). Fallback: `SourceSans`.

### "+N" Popup Animation

- Spawn position: center of dice box, 0 px offset
- End position: 50 px above spawn
- Duration: 1.0 s
- Easing: `Enum.EasingStyle.Cubic`, `Enum.EasingDirection.Out`
- Opacity: 1.0 → 0.0 over same duration
- Destroy on completion

## Input States

| State | Roll Button Visual |
|-------|--------------------|
| Default | `buttonDefault`, scale 1.0 |
| Hover | `buttonHover`, scale 1.05 |
| Pressed | `buttonDefault`, scale 0.95 |
| Disabled (cooldown) | `buttonDisabled`, no interaction |

Hover/press transitions: 0.1 s linear.

## Dice Sprite

- Source: `D20.hex` hex-grid sprite in `src/Assets/Dice/`
- Rendered as an `ImageLabel` with `rbxassetid://` once uploaded
- Each tier applies its own `Color3` via `ImageColor3`
- Aspect ratio: roughly 16×17 hex grid → near-square, fits a square frame

## Performance Notes

- Max simultaneous dice in display: governed by owned count (up to ~20 realistically)
- Glow effects are lightweight (single ImageLabel per die, short-lived)
- No particle emitters in DiceDisplay — screen flash and particles are handled by GameHUD
- Tweens use `TweenService:Create` (pooled, no per-frame GC pressure)
