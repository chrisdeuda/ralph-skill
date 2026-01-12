---
description: Initialize a new Ralph plan directory with tasks template
argument-hint: "<slug>"
---

# Ralph Init - Create New Plan

Create a new plan directory with the required structure for Ralph to work on.

## Arguments
- `$ARGUMENTS` contains the plan slug (e.g., "my-feature", "fix-bug")

## What This Creates

```
plans/{date}-{slug}/
├── tasks.md      # Task file with checkboxes
├── context.md    # Key files to focus on (optional)
└── progress.md   # Auto-generated progress log
```

## Instructions

1. Parse the slug from `$ARGUMENTS`
2. If no slug provided, ask the user what they want to work on
3. Create the plan directory: `plans/YYMMDD-{slug}/`
4. Create `tasks.md` from template with:
   - Phase 1: Prototype tasks (no tests)
   - CHECKPOINT task for manual verification
   - Phase 2: Quality tasks (tests, lint)
5. Create empty `progress.md`
6. Optionally create `context.md` if user specifies key files

## Template Structure

```markdown
# {Feature Name}

## Phase 1: Prototype (RALPH_MODE=prototype)

- [ ] Task 1: Core functionality
  - **AC:** What done looks like
- [ ] Task 2: Another feature
  - **AC:** Acceptance criteria

## CHECKPOINT

- [ ] CHECKPOINT: Manual verification
  - **AC:** Manually test the prototype works
  - **PAUSE:** Stop here, verify before Phase 2

## Phase 2: Quality (RALPH_MODE=production)

- [ ] Add unit tests for core functionality
  - **AC:** Tests pass, coverage adequate
- [ ] Fix lint errors
  - **AC:** npm run lint passes
```

## Usage Examples

```
/ralph-init my-feature      # Creates plans/260112-my-feature/
/ralph-init fix-login-bug   # Creates plans/260112-fix-login-bug/
```
