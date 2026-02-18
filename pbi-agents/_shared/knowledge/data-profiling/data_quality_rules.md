# Data Quality Rules

## Critical Rules (Must Fix Before Modeling)

1. **No orphan foreign keys.** Every FK value must exist in the parent table.
2. **No duplicate primary keys.** PKs must be unique and non-null.
3. **Date columns must be valid dates.** No text dates, no mixed formats.
4. **Numeric columns must be numeric.** No text in amount/quantity fields.

## Warning Rules (Document and Assess)

1. **High null percentage** (>20%) — may indicate data quality issue or optional field.
2. **Low cardinality in expected-high columns** — may indicate data truncation.
3. **Future dates in historical data** — may indicate timezone or entry errors.
4. **Negative values in positive-only fields** — may indicate corrections or errors.

## Informational Rules (Log for Reference)

1. **Column naming inconsistency** — document for naming convention alignment.
2. **Unused columns** — flag for potential removal during modeling.
3. **Implicit hierarchies** — identify natural drill paths (Country > State > City).
