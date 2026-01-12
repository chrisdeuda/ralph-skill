# Ralph Design Philosophy

## Core Principle

> **Validate First, Polish Later** - Get it working before making it pretty.

## The Workflow

```
Phase 1: Prototype  →  CHECKPOINT  →  Phase 2: Quality
(no tests/lint)       (manual verify)   (tests/lint/polish)
```

## Why This Exists

Real case: Tests passed (5/5) but API was wrong. Hours wasted on tests for broken code.

**Solution:** Human verifies core works BEFORE writing tests.

## Quick Reference

| Command | Purpose |
|---------|---------|
| `ralph-review <plan>` | Surface unclear requirements |
| `ralph-afk <plan> N auto prototype` | Phase 1: Make it work |
| `ralph-afk <plan> N auto production` | Phase 2: Add quality |

## Detailed Docs

For full explanations, see `docs/` folder:
- `docs/phases.md` - Why Prototype → Checkpoint → Quality
- `docs/task-structure.md` - Required task file format
- `docs/learnings.md` - Key lessons from real projects
