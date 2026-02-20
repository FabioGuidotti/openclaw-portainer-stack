# PBIP — Mandatory File Structure

> **CRITICAL**: Every PBIP project MUST contain ALL files listed below. Power BI Desktop will refuse to open the project if any are missing, with error: *"Required artifact is missing in definition.pbism"*.

## Complete File Tree

```
<ProjectName>/
├── <ProjectName>.pbip                          ← root manifest
├── <ProjectName>.SemanticModel/
│   ├── .pbi/
│   │   └── localSettings.json                  ← local dataset reference
│   ├── .platform                               ← Fabric metadata (SemanticModel)
│   ├── definition.pbism                        ← ⚠️ REQUIRED — semantic model manifest
│   ├── definition/
│   │   ├── database.tmdl                       ← ⚠️ REQUIRED — compatibility level
│   │   ├── model.tmdl                          ← model config, culture, table refs
│   │   ├── expressions.tmdl                    ← Power Query M expressions (if any)
│   │   ├── relationships.tmdl                  ← table relationships
│   │   ├── tables/
│   │   │   └── <TableName>.tmdl                ← one file per table
│   │   └── cultures/
│   │       └── <locale>.tmdl                   ← e.g. pt-BR.tmdl
│   └── diagramLayout.json                      ← optional, diagram positions
└── <ProjectName>.Report/
    ├── .pbi/
    │   └── localSettings.json                  ← local report settings
    ├── .platform                               ← Fabric metadata (Report)
    ├── definition.pbir                         ← ⚠️ REQUIRED — report manifest + dataset link
    ├── definition/
    │   ├── report.json                         ← report layout and config
    │   ├── version.json                        ← report format version
    │   └── pages/
    │       ├── pages.json                      ← page order
    │       └── page_XX.json                    ← one file per page
    ├── StaticResources/                        ← images, custom visuals (if any)
    └── settings.json                           ← optional report settings
```

## Scaffolding File Templates

### `<ProjectName>.pbip`

```json
{
  "$schema": "https://developer.microsoft.com/json-schemas/fabric/pbip/pbipProperties/1.0.0/schema.json",
  "version": "1.0",
  "artifacts": [
    {
      "report": {
        "path": "<ProjectName>.Report"
      }
    }
  ],
  "settings": {
    "enableAutoRecovery": true
  }
}
```

### `<ProjectName>.SemanticModel/definition.pbism`

```json
{
  "$schema": "https://developer.microsoft.com/json-schemas/fabric/item/semanticModel/definitionProperties/1.0.0/schema.json",
  "version": "4.2",
  "settings": {}
}
```

### `<ProjectName>.SemanticModel/.platform`

```json
{
  "$schema": "https://developer.microsoft.com/json-schemas/fabric/gitIntegration/platformProperties/2.0.0/schema.json",
  "metadata": {
    "type": "SemanticModel",
    "displayName": "<ProjectName>"
  },
  "config": {
    "version": "2.0",
    "logicalId": "<generate-a-new-uuid>"
  }
}
```

### `<ProjectName>.SemanticModel/definition/database.tmdl`

```
database
	compatibilityLevel: 1600
```

### `<ProjectName>.Report/definition.pbir`

```json
{
  "$schema": "https://developer.microsoft.com/json-schemas/fabric/item/report/definitionProperties/2.0.0/schema.json",
  "version": "4.0",
  "datasetReference": {
    "byPath": {
      "path": "../<ProjectName>.SemanticModel"
    }
  }
}
```

### `<ProjectName>.Report/.platform`

```json
{
  "$schema": "https://developer.microsoft.com/json-schemas/fabric/gitIntegration/platformProperties/2.0.0/schema.json",
  "metadata": {
    "type": "Report",
    "displayName": "<ProjectName>"
  },
  "config": {
    "version": "2.0",
    "logicalId": "<generate-a-new-uuid>"
  }
}
```

## Validation Checklist

Before declaring a PBIP project complete, verify **ALL** exist:

- [ ] `<ProjectName>.pbip`
- [ ] `<ProjectName>.SemanticModel/definition.pbism`
- [ ] `<ProjectName>.SemanticModel/.platform`
- [ ] `<ProjectName>.SemanticModel/definition/database.tmdl`
- [ ] `<ProjectName>.SemanticModel/definition/model.tmdl`
- [ ] `<ProjectName>.Report/definition.pbir`
- [ ] `<ProjectName>.Report/.platform`
- [ ] `<ProjectName>.Report/definition/report.json`
- [ ] At least one `<ProjectName>.SemanticModel/definition/tables/*.tmdl`

## Common Errors

| Error | Cause | Fix |
|---|---|---|
| "Required artifact is missing in definition.pbism" | `definition.pbism` file is missing from `.SemanticModel/` | Create the file with the template above |
| "DatasetDefinition: Required artifact is missing" | `database.tmdl` or `model.tmdl` missing from `definition/` | Create both files |
| Report opens but shows no data | `definition.pbir` missing or has wrong `datasetReference.byPath.path` | Fix the relative path to point to the `.SemanticModel` folder |
