---
description: Run Ralph in AFK loop mode (away-from-keyboard autonomous)
argument-hint: "<plan-path> <iterations> [model] [mode]"
---

# Ralph AFK - Autonomous Loop

Run multiple iterations autonomously. Best for bulk work and overnight runs.

## Arguments
- `$ARGUMENTS` contains: `<plan-path> <iterations> [model] [mode]`
  - plan-path: Required. Path to plan directory
  - iterations: Required. Number of iterations (1-50)
  - model: Optional. haiku|sonnet|opus|auto (default: auto)
  - mode: Optional. prototype|production (default: prototype)

## When to Use

- Bulk implementation tasks
- Low-risk, well-defined work
- Overnight or unattended runs
- After reviewing plan with `/ralph-review`

## Instructions

Execute the AFK loop by running the shell script:

```bash
~/.claude/skills/ralph/scripts/ralph-afk.sh <plan-path> <iterations> [model] [mode]
```

The script will:
1. Loop N times (or until all tasks done)
2. Auto-select model based on task keywords
3. Pause at CHECKPOINT tasks
4. Log all activity to progress.md
5. Exit on errors or ALL_TASKS_DONE

## Recommended Workflow

```
1. /ralph-init my-feature           # Create plan
2. Edit tasks.md                    # Add tasks
3. /ralph-review plans/260112-.../  # Check for issues
4. /ralph-afk plans/260112-.../ 5 auto prototype  # Phase 1
   → Ralph auto-pauses at CHECKPOINT
5. Manual test                      # Verify it works!
6. /ralph-afk plans/260112-.../ 5 auto production # Phase 2
```

## Mode Behaviors

| Mode | Tests | Lint | Edge Cases |
|------|-------|------|------------|
| prototype | ❌ | ❌ | ❌ |
| production | ✅ | ✅ | ✅ |

## Usage Examples

```
/ralph-afk plans/260112-my-feature/ 5                        # 5 iterations, auto/prototype
/ralph-afk plans/260112-my-feature/ 10 haiku                 # 10 iterations, haiku
/ralph-afk plans/260112-my-feature/ 5 auto production        # Production mode
```

## Safety

- Always cap iterations (recommended: 5-10 small, 30-50 large)
- Use CHECKPOINT tasks between prototype and production phases
- Monitor progress.md for errors
