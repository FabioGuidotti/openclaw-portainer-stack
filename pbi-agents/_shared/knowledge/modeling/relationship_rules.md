# Relationship Rules (Power BI)

## Cardinality

| Type | Rule |
|------|------|
| One-to-Many (1:N) | Default. Dimension → Fact. |
| One-to-One (1:1) | Rare. Consider merging tables. |
| Many-to-Many (M:N) | Avoid. Use bridge table instead. |

## Cross-Filter Direction

| Direction | When to Use |
|---|---|
| Single | Default. Fact filters from Dimension. |
| Both | Only when explicitly justified (impacts performance). |

## Rules

1. **Every relationship must have a clear business meaning.**
2. **Avoid ambiguous relationships** — Power BI does not allow multiple active paths.
3. **Use USERELATIONSHIP()** for inactive relationships in DAX.
4. **No circular dependencies** — validate graph before finalizing.
5. **Referential integrity** — enable "Assume referential integrity" for DirectQuery performance.

## Common Pitfalls

- ❌ Bidirectional relationship "just to make a slicer work"
- ❌ Multiple active relationships between same tables
- ❌ Using TEXT keys for relationships (use INTEGER)
- ❌ Missing Date table relationship
