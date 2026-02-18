# Star Schema Patterns

## Core Pattern

```
     Dim_Date
        │
Dim_A ──┤
        │── Fact_Table
Dim_B ──┤
        │
     Dim_C
```

- Fact tables contain measures (numeric) and foreign keys.
- Dimension tables contain descriptive attributes.
- All relationships go from dimension to fact (one-to-many).

## Dimension Types

| Type | Description | Example |
|------|-------------|---------|
| Conformed | Shared across multiple facts | Date, Customer |
| Role-Playing | Same dimension used multiple times | OrderDate, ShipDate |
| Degenerate | Dimension stored in fact table | Invoice Number |
| Junk | Combined low-cardinality flags | Yes/No combinations |
| Outrigger | Dimension of a dimension | City → State → Country |

## SCD (Slowly Changing Dimensions)

| Type | Strategy | Use When |
|------|----------|----------|
| Type 1 | Overwrite | History not needed |
| Type 2 | Add new row | Full history needed |
| Type 3 | Add column | Only current + previous needed |

## Power BI Specifics

- Always create a dedicated Date dimension (not auto date/time).
- Use INTEGER surrogate keys for relationships when possible.
- Star schema outperforms snowflake in DirectQuery mode.
- Limit snowflake to cases where dimension tables are very large.
