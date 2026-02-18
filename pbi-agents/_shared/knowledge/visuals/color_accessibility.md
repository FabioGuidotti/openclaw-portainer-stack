# Color Accessibility

## WCAG Compliance

- Minimum contrast ratio: **4.5:1** for normal text
- Minimum contrast ratio: **3:1** for large text and UI components
- Never rely on color alone to convey information — add labels/patterns

## Color Palette Guidelines

1. Limit to 5-7 colors maximum in a report
2. Use a single hue with varying saturation for sequential data
3. Use diverging palettes (blue ↔ red) for positive/negative
4. Avoid red/green only combinations (colorblind-unfriendly)

## Colorblind-Safe Palettes

### Option A: Blue-Orange
- Primary: `#2171B5`, Secondary: `#E66101`

### Option B: Blue-Grey
- Primary: `#2171B5`, Secondary: `#636363`

### Option C: Categorical (6 colors)
```
#4E79A7, #F28E2B, #E15759, #76B7B2, #59A14F, #EDC948
```

## Power BI Specific

- Set theme colors in `.json` theme file for consistency
- Use conditional formatting with accessible color scales
- Always include data labels when colors are the primary differentiator
