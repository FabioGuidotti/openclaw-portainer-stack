# Naming Conventions

## Tables

| Type | Pattern | Example |
|------|---------|---------|
| Fact | `Fact_<Subject>` | `Fact_Sales`, `Fact_Inventory` |
| Dimension | `Dim_<Entity>` | `Dim_Customer`, `Dim_Date` |
| Bridge | `Bridge_<Relationship>` | `Bridge_CustomerProduct` |
| Staging | `Stg_<Source>_<Table>` | `Stg_ERP_Orders` |

## Columns

| Type | Pattern | Example |
|------|---------|---------|
| Primary Key | `<Table>Key` or `<Table>ID` | `CustomerKey`, `ProductID` |
| Foreign Key | `<ReferencedTable>Key` | `CustomerKey` in Fact_Sales |
| Measure | Descriptive name | `Total Sales`, `Avg Unit Price` |
| Date | `<Context>Date` | `OrderDate`, `ShipDate` |
| Flag | `Is<Condition>` | `IsActive`, `IsDeleted` |
| Amount | `<Subject>Amount` | `SalesAmount`, `DiscountAmount` |
| Count | `<Subject>Count` | `OrderCount`, `LineItemCount` |

## Measures

- Use spaces in measure names for readability: `Total Sales Amount`
- Prefix with category in large models: `Sales | Total Amount`
- Always include a description in the measure properties

## General Rules

- No spaces in table names (use underscores)
- Spaces OK in column and measure display names
- CamelCase or PascalCase for technical names
- Be consistent — pick one convention and stick to it
