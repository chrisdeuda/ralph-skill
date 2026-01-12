---
description: Show Ralph status dashboard with progress across all plans
argument-hint: "[watch]"
---

# Ralph Status - Progress Dashboard

View progress across all plans in a visual dashboard.

## Arguments
- `$ARGUMENTS` contains: `[watch]`
  - watch: Optional. Continuously refresh every 5 seconds

## What It Shows

- All plans in `plans/` directory
- Task completion percentage with progress bar
- Current/next task for each plan
- Last activity timestamp
- Recent entries from ralph-log.md

## Instructions

Run the status dashboard:

```bash
~/.claude/skills/ralph/scripts/ralph-status.sh [watch]
```

## Output Format

```
═══════════════════════════════════════════════════════════════
                    RALPH STATUS DASHBOARD
═══════════════════════════════════════════════════════════════

┌─ 260112-my-feature
│  ▶ IN PROGRESS  [████████░░░░░░░░░░░░] 40% (4/10 tasks)
│  Next: Implement user authentication...
│  Last: 2026-01-12 15:30
└─

┌─ 260111-fix-bug
│  ✓ DONE  [████████████████████] 100% (5/5 tasks)
└─

═══════════════════════════════════════════════════════════════
                    RECENT ACTIVITY (ralph-log.md)
═══════════════════════════════════════════════════════════════
[2026-01-12 15:30] Completed: Task 4 - Add form validation
[2026-01-12 15:25] Started: Task 4 - Add form validation

───────────────────────────────────────────────────────────────
Updated: 2026-01-12 15:35:00
Watch global log: tail -f plans/ralph-log.md
```

## Usage Examples

```
/ralph-status          # Show dashboard once
/ralph-status watch    # Continuously refresh
```
