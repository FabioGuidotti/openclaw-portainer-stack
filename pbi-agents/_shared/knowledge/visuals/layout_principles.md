# Layout Principles

## Page Structure

```
┌──────────────────────────────────────────┐
│  Title / Navigation Bar                  │
├──────────┬───────────────────────────────┤
│ Slicers  │  KPI Cards (3-4)             │
│          ├───────────────────────────────┤
│          │  Main Chart 1  │ Main Chart 2 │
│          ├───────────────────────────────┤
│          │  Detail Table / Matrix        │
└──────────┴───────────────────────────────┘
```

## Rules

1. **Z-pattern reading**: Important content top-left → top-right → bottom-left → bottom-right
2. **Slicers on the left or top**: Consistent placement across pages
3. **KPIs first**: Show summary before detail
4. **Whitespace matters**: Don't crowd visuals — use margins
5. **Consistent sizing**: Align visual boundaries to a grid
6. **Page navigation**: Use bookmarks or buttons for multi-page reports

## Responsive Design

- Design at 16:9 for desktop
- Create separate mobile layout in Power BI Desktop
- Limit mobile to 3-4 visuals per view
- Stack vertically on mobile — no side-by-side
