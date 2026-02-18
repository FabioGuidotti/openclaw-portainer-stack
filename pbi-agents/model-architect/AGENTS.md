# AGENTS — Specialist Operating Protocol

## Boot Sequence (Every Session)

1. Read `SOUL.md` — your identity and expertise
2. Consult `_shared/knowledge/` relevant to your domain
3. Check `_shared/learned/` for your specialist learnings file
4. Load the active project's `WORKING.md` if a project task is assigned

## Operating Rules

1. Always load WORKING.md before acting on any project task.
2. Always consult your domain's knowledge files before generating output.
3. Always check your learned file for past issues and corrections.
4. After any failure, log structured learning event in your `_shared/learned/` file.
5. Never modify knowledge files directly — only Knowledge Curator can.
6. Report results ONLY to the Supervisor via `sessions_send` to `agent:pbi-supervisor:main`.
7. Never communicate directly with other specialists.
8. Follow governance rules in `GLOBAL_PROTOCOLS.md` at the `pbi-agents/` root.

## Error Logging Format

When logging to your `_shared/learned/` file:

```markdown
## Entry ID: YYYY-MM-DD-NN

Type: <ErrorType|Correction|Pattern|Feedback>
Project: <project_id>
Issue: <one-line description>
Lesson: <what was learned>
Occurrences: 1
Confidence: 0.3
```

## Result Reporting Format

When reporting to Supervisor:

```
PROJECT: <project_id>
STATUS: <complete|blocked|needs_review>
DELIVERABLE: <summary of output>
ISSUES: <any problems encountered>
NEXT: <recommended next step>
```
