# GLOBAL PROTOCOLS — PBI Agent Governance

System-wide rules that govern ALL PBI agents. Referenced by every agent's `AGENTS.md`.

## 1. Drift Control

- **Learned NEVER replaces Knowledge.** Learned only complements.
- **Knowledge ONLY changes via Knowledge Curator** (agent `pbi-knowledge-curator`).
- **Supervisor can require human validation** before promoting learned rules.

## 2. Communication Rules

- Specialists **NEVER** communicate directly with each other.
- All inter-agent communication goes through the **Supervisor**.
- Flow: `Specialist → writes result → Supervisor validates → routes to next agent`
- Use `sessions_send` to the Supervisor session: `agent:pbi-supervisor:main`

## 3. Knowledge Access

- Agents read `_shared/knowledge/<domain>/` relevant to their specialization.
- **Do NOT load all knowledge files.** Only load what is relevant to the current task.
- Never modify knowledge files directly.

## 4. Learned Memory Protocol

All entries in `_shared/learned/` MUST follow this format:

```markdown
## Entry ID: YYYY-MM-DD-NN

Type: <ErrorType|Correction|Pattern|Feedback>
Project: <project_id>
Issue: <one-line description>
Lesson: <what was learned>
Occurrences: <count>
Confidence: <0.0 to 1.0>
```

Rules:
- Initial confidence for new entries: `0.3`
- Human feedback entries start at: `0.3`
- If similar feedback occurs 3+ times: confidence increases to `0.6`
- Only Knowledge Curator promotes entries with confidence ≥ `0.8` to knowledge

## 5. Evolution Control (Knowledge Curator)

The Knowledge Curator (`pbi-knowledge-curator`) runs weekly:
1. Read all `_shared/learned/*` files
2. Detect recurring patterns (3+ occurrences)
3. Increase confidence scores
4. If confidence ≥ 0.8 threshold:
   - Update `_shared/knowledge/*` (add new entry)
   - Update this file if governance rules need adjustment
5. Require Supervisor validation for critical changes

## 6. Human Feedback Integration

When a human provides feedback (e.g., via Discord):
1. Supervisor interprets the feedback
2. Creates structured entry in appropriate `_shared/learned/*.md`
3. Sets initial confidence = `0.3`
4. If feedback repeats 3+ times → confidence escalates

## 7. LLM Model Tiers

| Action | Recommended Tier |
|---|---|
| Heartbeat check | Cheap/fast model |
| Clarification | Medium model |
| Complex DAX/Modeling | Strong model |
| Knowledge Curation | Strong model |
| Research | Medium model |

## 8. Working Context Protocol

Every agent MUST:
1. Load `_shared/projects/<id>/WORKING.md` before acting
2. Update `WORKING.md` after completing work
3. Never skip checking working context

## 9. Critical Errors to Avoid

- ❌ Creating agents before stabilizing existing ones
- ❌ Allowing self-modification of knowledge by specialists
- ❌ Not versioning knowledge changes
- ❌ Not registering structured errors in learned
- ❌ Allowing unrestricted direct communication between specialists
