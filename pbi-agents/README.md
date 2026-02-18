# PBI Agents — Multi-Agent System for Power BI (OpenClaw)

A governance-driven multi-agent system for Power BI development, running on **OpenClaw**.

## Architecture

```
portainer-stack.yml → agents.list[]
    │
    ├── supervisor/          (Orchestrator — controls all communication)
    ├── data-profiler/       (Data quality & schema analysis)
    ├── model-architect/     (Star schema & dimensional modeling)
    ├── dax-specialist/      (DAX measures & filter context)
    ├── visual-designer/     (Report layout & chart selection)
    ├── builder/             (PBIX assembly & deployment)
    ├── knowledge-curator/   (Weekly curation: learned → knowledge)
    └── research-agent/      (Best practices & benchmarks)

    _shared/
    ├── knowledge/           (Stable reference — read-only by agents)
    ├── learned/             (Evolutionary memory — agents append)
    └── projects/            (Per-project working context)
```

## How It Works

Each agent is an **isolated OpenClaw agent** with its own workspace:

- `SOUL.md` — Identity, expertise, principles (auto-injected every session)
- `AGENTS.md` — Operating protocol (auto-injected every session)
- `HEARTBEAT.md` — Wake-up checklist for periodic heartbeats

Communication flows **only through the Supervisor** via `sessions_send`.

## Agent Roles

| Agent | ID | Purpose |
|---|---|---|
| **Supervisor** | `pbi-supervisor` | Orchestrates, validates, routes tasks |
| **DataProfiler** | `pbi-data-profiler` | Analyzes source data quality |
| **ModelArchitect** | `pbi-model-architect` | Designs dimensional models |
| **DAXSpecialist** | `pbi-dax-specialist` | Writes & validates DAX |
| **VisualDesigner** | `pbi-visual-designer` | Designs report UX |
| **Builder** | `pbi-builder` | Assembles & deploys PBIX |
| **KnowledgeCurator** | `pbi-knowledge-curator` | Promotes learned → knowledge |
| **ResearchAgent** | `pbi-research-agent` | Researches best practices |

## Setup

### 1. Deploy Stack
The agents are registered in `portainer-stack.yml`. Redeploy the stack after setup.

### 2. Shared Resources
- `_shared/knowledge/` — Stable reference material (agents read, never write)
- `_shared/learned/` — Evolutionary memory (agents append structured entries)
- `_shared/projects/` — Per-project working context (copy `TEMPLATE/`)

### 3. Implementation Order
1. Supervisor → 2. DataProfiler → 3. ModelArchitect → 4. DAXSpecialist → 5. VisualDesigner → 6. Builder → 7. KnowledgeCurator → 8. ResearchAgent

## Governance Rules
See [GLOBAL_PROTOCOLS.md](GLOBAL_PROTOCOLS.md) for drift control, evolution rules, and human feedback integration.
