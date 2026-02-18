# Data Profiling Checklist

## Pre-Profiling
- [ ] Identify all source tables and their origin systems
- [ ] Document expected row counts and refresh frequency
- [ ] Identify primary keys and candidate keys

## Column Analysis
For each column, document:
- **Data type**: text, integer, decimal, date, boolean
- **Nullability**: percentage of null values
- **Uniqueness**: percentage of distinct values
- **Distribution**: min, max, avg, median, mode
- **Outliers**: values outside 3σ or business-defined ranges

## Relationship Analysis
- [ ] Identify candidate foreign keys
- [ ] Test referential integrity (orphan records)
- [ ] Document cardinality (1:1, 1:N, M:N)
- [ ] Flag many-to-many relationships for bridge table consideration

## Data Quality Checks
- [ ] Duplicate detection (exact and fuzzy)
- [ ] Consistency checks (e.g., dates in future, negative amounts)
- [ ] Completeness (required fields with nulls)
- [ ] Format validation (phone numbers, emails, codes)

## Output Template

```
TABLE: <name>
ROWS: <count>
SOURCE: <system>

COLUMNS:
| Column | Type | Nulls% | Distinct | Notes |
|--------|------|--------|----------|-------|

RELATIONSHIPS:
| From | To | Key | Cardinality | Integrity |
|------|-----|-----|-------------|-----------|

ISSUES:
- <issue description>
```
