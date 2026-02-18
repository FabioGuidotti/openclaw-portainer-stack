# DAX Anti-Patterns

## ❌ Nested CALCULATE Without Justification

```dax
-- BAD: unnecessary nesting
Bad Measure = 
CALCULATE(
    CALCULATE(
        SUM(Sales[Amount]),
        ALL(Dim_Date)
    ),
    Dim_Product[Category] = "A"
)

-- GOOD: flatten
Good Measure = 
CALCULATE(
    SUM(Sales[Amount]),
    ALL(Dim_Date),
    Dim_Product[Category] = "A"
)
```

## ❌ Using FILTER on Large Tables Without Need

```dax
-- BAD: FILTER iterates row by row on 1M rows
Bad = CALCULATE(SUM(Sales[Amount]), FILTER(Sales, Sales[Qty] > 10))

-- GOOD: use direct predicate when possible
Good = CALCULATE(SUM(Sales[Amount]), Sales[Qty] > 10)
```

## ❌ SUMX Instead of SUM

```dax
-- BAD: iterator when simple aggregation works
Bad = SUMX(Sales, Sales[Amount])

-- GOOD: direct aggregation
Good = SUM(Sales[Amount])
```

## ❌ No BLANK() Handling

```dax
-- BAD: division without protection
Bad Margin = Sales[Revenue] / Sales[Cost]

-- GOOD: DIVIDE handles zero/blank
Good Margin = DIVIDE(Sales[Revenue], Sales[Cost], BLANK())
```

## ❌ Hardcoded Values

```dax
-- BAD: hardcoded threshold
Bad = IF(SUM(Sales[Amount]) > 1000000, "High", "Low")

-- GOOD: use a parameter or What-If table
Good = IF(SUM(Sales[Amount]) > [Threshold Value], "High", "Low")
```

## ❌ Missing VAR for Readability

```dax
-- BAD: repeated calculation
Bad = 
DIVIDE(
    SUM(Sales[Amount]) - CALCULATE(SUM(Sales[Amount]), SAMEPERIODLASTYEAR(Dim_Date[Date])),
    CALCULATE(SUM(Sales[Amount]), SAMEPERIODLASTYEAR(Dim_Date[Date]))
)

-- GOOD: use VARs
Good = 
VAR Current = SUM(Sales[Amount])
VAR Prior = CALCULATE(SUM(Sales[Amount]), SAMEPERIODLASTYEAR(Dim_Date[Date]))
RETURN DIVIDE(Current - Prior, Prior)
```

## ❌ Calculated Columns for Measures

- Calculated columns increase model size
- Use measures unless you need the value for relationships or sorting
