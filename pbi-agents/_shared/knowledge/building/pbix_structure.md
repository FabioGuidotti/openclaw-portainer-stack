# PBIX Structure

## Components

| Component | Location | Purpose |
|-----------|----------|---------|
| Data Model | Model view | Tables, relationships, measures |
| Power Query | Transform view | ETL/data loading |
| Report Pages | Report view | Visuals and layout |
| Theme | External `.json` | Colors, fonts, visual defaults |

## Pre-Build Checklist

- [ ] All dimension and fact tables loaded
- [ ] Relationships configured and validated
- [ ] Date table marked as Date Table
- [ ] All measures created with descriptions
- [ ] Measure display folders organized
- [ ] Unused columns hidden
- [ ] Column data types verified
- [ ] Sort-by-column configured where needed

## Best Practices

1. Keep Power Query steps clean and documented
2. Use query folding when possible (especially DirectQuery)
3. Disable auto date/time in Options
4. Set appropriate data category for geography columns
5. Use measure tables (display folders) to organize measures
