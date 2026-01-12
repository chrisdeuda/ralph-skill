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
- ✅ Write unit tests
- ✅ Write e2e tests
- ✅ Fix lint errors
- ✅ Handle edge cases
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
