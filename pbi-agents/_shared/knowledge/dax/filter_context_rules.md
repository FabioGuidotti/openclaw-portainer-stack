# Filter Context Rules

## The Two Contexts

| Context | What It Is | Created By |
|---------|-----------|------------|
| **Filter Context** | Filters applied to the model | Slicers, rows/columns in visual, CALCULATE |
| **Row Context** | Current row during iteration | Calculated columns, iterators (SUMX, FILTER) |

## Context Transition

`CALCULATE` performs **context transition**: it converts any active Row Context into an equivalent Filter Context.

```dax
-- In a calculated column, this triggers context transition:
Sales for Row = CALCULATE(SUM(Fact_Sales[SalesAmount]))
-- The row context (current row) becomes a filter context
```

### When Context Transition Happens
1. Inside `CALCULATE` when there's an active row context
2. A measure reference inside an iterator (implicit CALCULATE)

### Implications
- Every column of the current row becomes a filter
- Can cause **unexpected cross-filtering**
- Performance impact: creates one filter per column

## CALCULATE Filter Arguments

```dax
-- Filter arguments REPLACE existing filters on that column
CALCULATE(
    SUM(Fact_Sales[SalesAmount]),
    Dim_Date[Year] = 2024        -- Replaces any Year filter
)

-- KEEPFILTERS intersects instead of replacing
CALCULATE(
    SUM(Fact_Sales[SalesAmount]),
    KEEPFILTERS(Dim_Date[Year] = 2024)  -- AND with existing filters
)
```

## Common Mistakes

1. **Forgetting context transition in measures used inside iterators**
2. **Using ALL when REMOVEFILTERS is clearer** 
3. **Not understanding filter replacement** (CALCULATE args replace, not add)
4. **Circular dependency** from calculated columns using CALCULATE on same table
