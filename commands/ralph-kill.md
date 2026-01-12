---
description: Kill Claude processes spawned by Ralph
argument-hint: "[--all|--list|--clean]"
---

# Ralph Kill - Stop Running Processes

Safely terminate Claude processes spawned by Ralph without affecting other Claude instances.

## Arguments
- `$ARGUMENTS` contains: `[--all|--list|--clean]`
  - (none): Kill only Ralph-spawned processes
  - --all: Kill ALL claude processes (use with caution)
  - --list: List tracked Ralph processes
  - --clean: Clean up stale PIDs

## How It Works

Ralph tracks PIDs of spawned Claude processes in `~/.ralph-pids`. This allows selective termination without killing unrelated Claude instances (like your IDE's Claude integration).

## Instructions

Run the kill script:

```bash
~/.claude/skills/ralph/scripts/ralph-kill.sh [option]
```

## Options

| Option | Description |
|--------|-------------|
| (none) | Kill only Ralph-spawned Claude processes |
| --all, -a | Kill ALL claude processes (dangerous!) |
| --list, -l | Show tracked PIDs and their status |
| --clean, -c | Remove stale (dead) PIDs from tracking |

## Usage Examples

```
/ralph-kill            # Kill Ralph processes only
/ralph-kill --list     # See what's being tracked
/ralph-kill --clean    # Clean up dead PIDs
/ralph-kill --all      # Nuclear option - kill everything
```

## When to Use

- Ralph is stuck in an infinite loop
- Need to stop an AFK run early
- Want to check if Ralph processes are running
- Cleaning up after crashes
