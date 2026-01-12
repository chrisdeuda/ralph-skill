---
description: Autonomous AI coding loop - show help and available commands
argument-hint: "[help]"
---

# Ralph - Autonomous AI Coding Loop

Run AI coding in a loop, working autonomously on tasks from your plans directory.

## Available Commands

| Command | Description |
|---------|-------------|
| `/ralph-init <slug>` | Create new plan directory with tasks template |
| `/ralph-review <plan>` | Review plan for unclear requirements |
| `/ralph-once <plan>` | Run single iteration (human-in-the-loop) |
| `/ralph-afk <plan> <N>` | Run N iterations autonomously |
| `/ralph-status` | Show progress dashboard |
| `/ralph-kill` | Stop Ralph processes |

## Quick Start

```bash
# 1. Create a plan
/ralph-init my-feature

# 2. Edit tasks.md with your tasks

# 3. Review for issues
/ralph-review plans/260112-my-feature/

# 4. Run Phase 1 (prototype)
/ralph-afk plans/260112-my-feature/ 5 auto prototype

# 5. Manual verification at CHECKPOINT

# 6. Run Phase 2 (production)
/ralph-afk plans/260112-my-feature/ 5 auto production
```

## Workflow Philosophy

```
Phase 1: Prototype  →  CHECKPOINT  →  Phase 2: Quality
(no tests/lint)       (manual test)   (tests/lint/polish)
```

**Why?** Real case: Tests passed (5/5) but API was wrong. Hours wasted.
**Solution:** Human verifies core works BEFORE writing tests.

## Quality Modes

| Mode | Tests | Lint | Edge Cases |
|------|-------|------|------------|
| prototype | ❌ | ❌ | ❌ |
| production | ✅ | ✅ | ✅ |

## Model Selection (auto)

| Task Keywords | Model | Cost |
|---------------|-------|------|
| lint, test, fix, docs, clean | Haiku | $ |
| implement, create, add, build | Sonnet | $$ |
| debug, architect, refactor | Opus | $$$ |

## Plan Structure

```
plans/{date}-{slug}/
├── tasks.md      # [ ] checkboxes with acceptance criteria
├── context.md    # Key files to focus on (saves tokens)
└── progress.md   # Auto-generated progress log
```

## More Info

- Type `/ralph-init` to create a new plan
- Type `/ralph-status` to see all plans
- Read `~/.claude/skills/ralph/CLAUDE.md` for design philosophy
