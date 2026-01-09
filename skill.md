---
name: ralph
description: Autonomous AI coding loop. Use when user wants to run tasks from a plan autonomously, go AFK while coding, or automate repetitive development work. Triggers on "ralph", "afk coding", "autonomous loop", "run tasks automatically".
---

# Ralph - Autonomous AI Coding Loop

Run AI coding in a loop, letting it work autonomously on a list of tasks from your plans directory.

## Modes

| Mode | Script | Use Case |
|------|--------|----------|
| HITL (human-in-the-loop) | `ralph-once` | Learning, prompt refinement, risky tasks |
| AFK (away from keyboard) | `ralph-afk` | Bulk work, low-risk tasks, overnight runs |

## Plan Structure

Ralph works with your existing plans directory:

```
plans/{date}-{slug}/
├── tasks.md      # Task file with checkboxes [ ] and [x]
└── progress.md   # Auto-generated progress log
```

## Usage

### Initialize Ralph in a project
```bash
# Create plan directory with tasks
ralph-init "my-feature"
# Creates: plans/260109-my-feature/tasks.md
```

### Run single iteration (HITL)
```bash
ralph-once plans/260109-my-feature/
# Or with model override:
ralph-once plans/260109-my-feature/ sonnet
```

### Run AFK loop
```bash
ralph-afk plans/260109-my-feature/ 5
# Runs 5 iterations with auto model selection
# Or with model override:
ralph-afk plans/260109-my-feature/ 10 haiku
```

## Model Selection

Ralph auto-selects models based on task keywords:

| Keywords | Model | Cost |
|----------|-------|------|
| lint, test, fix, docs, clean, format | Haiku | $ |
| implement, create, add, build | Sonnet | $$ |
| debug, architect, refactor, restructure | Opus | $$$ |

Override with second argument: `ralph-once <plan> opus`

## Task File Format (tasks.md)

```markdown
# Feature Name

## Tasks

- [ ] First task description
  - **AC:** Acceptance criteria
- [ ] Second task
  - **AC:** What done looks like
- [x] Completed task
```

## Progress Tracking

Ralph appends to `progress.md` (never overwrites):

```markdown
---
## Task N: [description]
**Status:** In Progress | **Time:** YYYY-MM-DD HH:MM | **Model:** sonnet

### Plan
- Step 1
- Step 2

### Actions
- [HH:MM] Action taken
- [HH:MM] ERROR: What failed (if any)
- [HH:MM] FIX: What was tried

### Result
**Status:** Completed | **Completed:** HH:MM
```

## Feedback Loops

Ralph runs these checks before marking complete:
1. `npm run lint -- --fix` (if available)
2. `npm test` (must pass)
3. Commits changes with descriptive message

## Best Practices

1. **Start HITL, then AFK** - Refine prompt before going hands-off
2. **Small tasks** - One feature per checkbox, not epics
3. **Risky tasks first** - Use HITL for architectural decisions
4. **Cap iterations** - Always limit AFK runs (5-10 small, 30-50 large)
5. **Delete progress.md after sprint** - It's session-specific

## Scripts

Run these from any project directory:

- `~/.claude/skills/ralph/scripts/ralph-init.sh` - Initialize plan
- `~/.claude/skills/ralph/scripts/ralph-once.sh` - Single iteration
- `~/.claude/skills/ralph/scripts/ralph-afk.sh` - AFK loop
- `~/.claude/skills/ralph/scripts/ralph-workflow.sh` - Shared workflow

## Installation

Add to your shell profile (~/.zshrc or ~/.bashrc):

```bash
# Ralph aliases
alias ralph-init="~/.claude/skills/ralph/scripts/ralph-init.sh"
alias ralph-once="~/.claude/skills/ralph/scripts/ralph-once.sh"
alias ralph-afk="~/.claude/skills/ralph/scripts/ralph-afk.sh"
```
