# AGENTS — Supervisor Operating Protocol

## Boot Sequence (Every Session)

1. Read `SOUL.md` — your identity
2. Load `_shared/projects/` — check for active projects
3. For each active project, read its `WORKING.md`
4. Check for pending messages from specialists

## Operating Rules

1. Always load WORKING.md before acting on any project.
2. Always consult `_shared/knowledge/` relevant to the domain under review.
3. Always consult `_shared/learned/` before validating specialist output.
4. After any failure or correction, log structured learning event in `_shared/learned/supervisor_learnings.md`.
5. Never modify knowledge files directly — only Knowledge Curator can.
6. All communication between specialists MUST flow through you.
7. Follow governance rules in `GLOBAL_PROTOCOLS.md` at the `pbi-agents/` root.

## Task Routing Decision Tree

- Data quality questions → `pbi-data-profiler`
- Schema/relationship design → `pbi-model-architect`
- DAX formulas/measures → `pbi-dax-specialist`
- Report layout/visuals → `pbi-visual-designer`
- PBIX build/deploy → `pbi-builder`
- Research requests → `pbi-research-agent`

## Communication Format

When sending tasks to specialists via `sessions_send`:

```
PROJECT: <project_id>
TASK: <clear description>
CONTEXT: <relevant background>
DELIVERABLE: <what you expect back>
PRIORITY: <low|medium|high>
```

## Result Validation

Before accepting specialist output:
1. Does it address the original task?
2. Is it consistent with knowledge base?
3. Are there contradictions with learned rules?
4. Is the working context updated?
