---
description: Run single Ralph iteration (human-in-the-loop mode)
argument-hint: "<plan-path> [model] [mode]"
---

# Ralph Once - Single Iteration (HITL)

Execute ONE task from the plan, then stop for human review.

## Arguments
- `$ARGUMENTS` contains: `<plan-path> [model] [mode]`
  - plan-path: Required. Path to plan directory
  - model: Optional. haiku|sonnet|opus|auto (default: auto)
  - mode: Optional. prototype|production (default: prototype)

## When to Use

- Learning how Ralph works
- Risky or complex tasks
- Debugging task execution
- Refining task descriptions

## Instructions

1. Read `<plan-path>/tasks.md` and `<plan-path>/context.md`
2. Find the next incomplete task `- [ ]`
3. If CHECKPOINT task: Mark complete, output instructions, exit
4. Append to `progress.md`:
   ```markdown
   ---
   ## Task N: [description]
   **Status:** In Progress | **Time:** YYYY-MM-DD HH:MM | **Model:** [model]
   ```
5. Implement the task following mode rules:
   - **prototype**: No tests, no lint, just make it work
   - **production**: Tests, lint, edge cases
6. Log actions to progress.md as you work
7. Mark task complete in tasks.md `[x]`
8. Commit changes
9. Output completion summary

## Model Selection (auto)

| Task Keywords | Model |
|---------------|-------|
| lint, test, fix, docs, clean, format | Haiku |
| implement, create, add, build, feature | Sonnet |
| debug, architect, refactor, restructure | Opus |

## Usage Examples

```
/ralph-once plans/260112-my-feature/                    # Auto model, prototype mode
/ralph-once plans/260112-my-feature/ sonnet             # Force sonnet
/ralph-once plans/260112-my-feature/ auto production    # Auto model, production mode
```
