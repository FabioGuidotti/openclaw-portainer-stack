# Workspace Management

## Power BI Service Workspaces

| Type | Purpose | Access |
|------|---------|--------|
| Development | Build and test | Developers only |
| Staging | User acceptance testing | Developers + reviewers |
| Production | End-user access | All stakeholders |

## Naming Convention

```
<Project>-<Environment>
Example: FinanceReport-DEV, FinanceReport-PROD
```

## Promotion Flow

```
DEV workspace → Staging workspace → PROD workspace
```

Use deployment pipelines in Power BI Premium/PPU when available.

## Access Control

- Workspace roles: Admin, Member, Contributor, Viewer
- Use security groups, not individual users
- Viewer role for report consumers
- Contributor role for report builders
