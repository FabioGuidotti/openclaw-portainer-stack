---
name: kanban-orchestrator
description: Kanban interface for the Manager Agent using Notion as the task board.
metadata:
  openclaw:
    emoji: 📋
    requires:
      bins: ["jq", "curl"]
      env: ["NOTION_API_KEY", "NOTION_DATABASE_ID"]
---

# Kanban Orchestrator Skill (Notion)

This skill allows the **Manager Agent** to act as "Mission Control" using a Notion database as the Kanban board.

## Setup

1. Create a Notion Integration at https://notion.so/my-integrations
2. Create a Notion Database with these properties:
   - **Name** (Title) — task name
   - **Status** (Select) — `To Do`, `Doing`, `Done`
   - **Label** (Select) — `dev`, `writing`, `research`
   - **Agent** (Rich Text) — which agent is working on it
   - **Result** (Rich Text) — output from the agent
3. Share the database with your integration (click "..." → "Connect to")
4. Set environment variables:
   ```bash
   export NOTION_API_KEY="ntn_your_key_here"
   export NOTION_DATABASE_ID="your_database_id"
   ```

## Actions

### `kanban_scan_inbox` — Get "To Do" tasks

```bash
NOTION_KEY="${NOTION_API_KEY}"
curl -s -X POST "https://api.notion.com/v1/databases/$NOTION_DATABASE_ID/query" \
  -H "Authorization: Bearer $NOTION_KEY" \
  -H "Notion-Version: 2022-06-28" \
  -H "Content-Type: application/json" \
  -d '{"filter": {"property": "Status", "select": {"equals": "To Do"}}}' \
  | jq '.results[] | {id, title: .properties.Name.title[0].text.content, label: .properties.Label.select.name}'
```

### `kanban_move_card` — Change task status

```bash
# Usage: kanban_move_card <page_id> <new_status>
curl -s -X PATCH "https://api.notion.com/v1/pages/$1" \
  -H "Authorization: Bearer $NOTION_KEY" \
  -H "Notion-Version: 2022-06-28" \
  -H "Content-Type: application/json" \
  -d "{\"properties\": {\"Status\": {\"select\": {\"name\": \"$2\"}}}}"
```

### `kanban_add_result` — Post agent output to the task

```bash
# Usage: kanban_add_result <page_id> <result_text>
curl -s -X PATCH "https://api.notion.com/v1/pages/$1" \
  -H "Authorization: Bearer $NOTION_KEY" \
  -H "Notion-Version: 2022-06-28" \
  -H "Content-Type: application/json" \
  -d "{\"properties\": {\"Result\": {\"rich_text\": [{\"text\": {\"content\": \"$2\"}}]}}}"
```

### `kanban_assign_agent` — Mark which agent is working

```bash
# Usage: kanban_assign_agent <page_id> <agent_name>
curl -s -X PATCH "https://api.notion.com/v1/pages/$1" \
  -H "Authorization: Bearer $NOTION_KEY" \
  -H "Notion-Version: 2022-06-28" \
  -H "Content-Type: application/json" \
  -d "{\"properties\": {\"Agent\": {\"rich_text\": [{\"text\": {\"content\": \"$2\"}}]}}}"
```

### `kanban_add_comment` — Add a block comment to the task page

```bash
# Usage: kanban_add_comment <page_id> <comment_text>
curl -s -X PATCH "https://api.notion.com/v1/blocks/$1/children" \
  -H "Authorization: Bearer $NOTION_KEY" \
  -H "Notion-Version: 2022-06-28" \
  -H "Content-Type: application/json" \
  -d "{\"children\": [{\"object\": \"block\", \"type\": \"paragraph\", \"paragraph\": {\"rich_text\": [{\"text\": {\"content\": \"$2\"}}]}}]}"
```

## Notes

- Database ID can be found in the Notion URL: `notion.so/<workspace>/<database_id>?v=...`
- Rate limit: ~3 requests/second average
- The existing `notion` skill in OpenClaw is also available for advanced operations
