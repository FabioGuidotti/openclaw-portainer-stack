# DAX Function Reference (Key Functions)

## Aggregation
| Function | Purpose | Example |
|----------|---------|---------|
| `SUM` | Sum of column | `SUM(Sales[Amount])` |
| `AVERAGE` | Average | `AVERAGE(Sales[UnitPrice])` |
| `COUNT` | Count non-blank | `COUNT(Sales[OrderID])` |
| `COUNTROWS` | Count rows in table | `COUNTROWS(Sales)` |
| `DISTINCTCOUNT` | Count unique values | `DISTINCTCOUNT(Sales[CustomerID])` |
| `MIN` / `MAX` | Minimum/Maximum | `MAX(Sales[OrderDate])` |

## Filter Modification
| Function | Purpose | Key Behavior |
|----------|---------|-------------|
| `CALCULATE` | Modify filter context | Context transition + filter args |
| `FILTER` | Row-by-row filter | Returns table, use inside CALCULATE |
| `ALL` | Remove all filters | Returns full table/column |
| `ALLEXCEPT` | Remove all filters except | Keep specific column filters |
| `REMOVEFILTERS` | Remove filters | Preferred over ALL in CALCULATE |
| `KEEPFILTERS` | Intersect filters | Adds filter instead of replacing |
| `VALUES` | Distinct values in context | Respects current filter context |

## Time Intelligence (Requires Date Table)
| Function | Purpose |
|----------|---------|
| `TOTALYTD` | Year-to-date total |
| `TOTALMTD` | Month-to-date total |
| `TOTALQTD` | Quarter-to-date total |
| `SAMEPERIODLASTYEAR` | Same period in previous year |
| `DATEADD` | Shift date range |
| `DATESYTD` | Dates from start of year |
| `PARALLELPERIOD` | Parallel period comparison |
| `PREVIOUSMONTH` | Previous month dates |

## Table Functions
| Function | Purpose |
|----------|---------|
| `SUMMARIZE` | Group by + aggregate |
| `ADDCOLUMNS` | Add calculated columns to table |
| `SELECTCOLUMNS` | Select specific columns |
| `CROSSJOIN` | Cartesian product |
| `UNION` | Combine tables |
| `EXCEPT` | Rows in A not in B |
| `INTERSECT` | Rows in both A and B |

## Iterators (X-functions)
| Function | Purpose |
|----------|---------|
| `SUMX` | Row-by-row sum | 
| `AVERAGEX` | Row-by-row average |
| `COUNTX` | Row-by-row count |
| `MAXX` / `MINX` | Row-by-row max/min |
| `RANKX` | Ranking |
