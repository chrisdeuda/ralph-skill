# Ralph Design Philosophy

## Core Principle

> **Validate First, Polish Later** - Get it working before making it pretty.

## The Workflow

```
Phase 1: Prototype  →  CHECKPOINT  →  Phase 2: Quality
(no tests/lint)       (manual verify)   (tests/lint/polish)
```

## CRITICAL RULES (Must Follow)

### In Prototype Mode (`RALPH_MODE=prototype`):
- ❌ NO unit tests
- ❌ NO e2e tests
- ❌ NO lint fixes
- ❌ NO edge cases
- ✅ Just make core functionality work
- ✅ Console.log verification is OK

### At CHECKPOINT Task:
- ⏸️ PAUSE execution
- 📢 Notify user for manual verification
- ⏳ Wait for human to test before Phase 2

### In Production Mode (`RALPH_MODE=production`):
- ✅ Write unit tests (vitest/jest - fast, run first)
- ✅ Fix lint errors
- ✅ Handle edge cases
- ✅ Write e2e tests (playwright - slow, run LAST)
- ✅ Code quality matters

## Why This Exists

Real case: Tests passed (5/5) but API was wrong. Hours wasted.

**Solution:** Human verifies core works BEFORE writing tests.

## Quick Reference

| Command | Purpose |
|---------|---------|
| `ralph-review <plan>` | Surface unclear requirements |
| `ralph-afk <plan> N auto prototype` | Phase 1: Make it work |
| `ralph-afk <plan> N auto production` | Phase 2: Add quality |

## Detailed Docs (read if needed)

- `docs/phases.md` - Why Prototype → Checkpoint → Quality
- `docs/task-structure.md` - Required task file format
- `docs/learnings.md` - Key lessons from real projects

## Multi-Machine Setup

When user mentions "air" or "MacBook Air", use SSH to sync (Syncthing often stops on Air).

### Update Ralph on Air
```bash
ssh air "cd ~/.claude/skills/ralph && git pull origin master"
```

### Add MCP to Air (claude CLI not in SSH PATH)
```bash
ssh air 'python3 -c "
import json
with open(\"/Users/chrisdeuda/.claude.json\", \"r\") as f:
    config = json.load(f)
config.setdefault(\"mcpServers\", {})[\"MCP_NAME\"] = {
    \"type\": \"stdio\",
    \"command\": \"npx\",
    \"args\": [\"package@latest\"],
    \"env\": {}
}
with open(\"/Users/chrisdeuda/.claude.json\", \"w\") as f:
    json.dump(config, f, indent=2)
print(\"MCP added\")
"'
```

### Full Sync Flow (after Ralph changes)
```bash
# 1. Push from current machine
cd ~/.claude/skills/ralph && git push origin master

# 2. Pull on Air
ssh air "cd ~/.claude/skills/ralph && git pull origin master"

# 3. Verify
ssh air "~/.claude/skills/ralph/scripts/ralph-playwriter.sh --status"
```

### Check Air Status
```bash
ssh air "hostname && cat ~/.claude.json | grep -A 4 playwriter"
```
