# Kanban Agent Team (Mission Control)

A "Manager Agent" that orchestrates a squad of AI workers using **Notion** as a Kanban board.

## Architecture

```
Notion Database (Kanban)
     │
     ▼
Manager Agent ("Mission Control")
     │
     ├─ sessions_spawn → Coder Agent
     ├─ sessions_spawn → Writer Agent
     └─ sessions_spawn → Researcher Agent
```

## Setup

### 1. Notion Integration
1. Go to https://notion.so/my-integrations → Create integration
2. Copy the API key (`ntn_...`)
3. Create a database with columns: **Name** (Title), **Status** (Select: To Do/Doing/Done), **Label** (Select: dev/writing/research), **Agent** (Text), **Result** (Text)
4. Share the database with your integration

### 2. Environment Variables
Set in Portainer or `.env`:
- `NOTION_API_KEY` — your integration key
- `NOTION_DATABASE_ID` — the database ID from the Notion URL

### 3. Running
```bash
openclaw agent --file prompts/manager.md
```

The Manager will scan Notion for "To Do" tasks, spawn workers, and update results.
