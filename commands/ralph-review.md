---
description: Review a plan for unclear requirements before starting work
argument-hint: "<plan-path>"
---

# Ralph Review - Pre-flight Check

Surface unclear requirements, ambiguities, and missing acceptance criteria BEFORE starting autonomous work.

## Arguments
- `$ARGUMENTS` contains the plan path (e.g., "plans/260112-my-feature/")

## Purpose

Catch problems before wasting iterations:
- Ambiguous task descriptions
- Missing acceptance criteria
- Unclear technical decisions
- Dependencies between tasks
- Missing context

## Instructions

1. Read `<plan-path>/tasks.md`
2. Read `<plan-path>/context.md` if it exists
3. For each task, check:
   - Is the task description clear and specific?
   - Are acceptance criteria measurable?
   - Are there implicit dependencies?
   - Is the scope appropriate for one iteration?
4. Output a review report with:
   - ✅ Clear tasks (ready to work)
   - ⚠️ Unclear tasks (need clarification)
   - ❌ Blocked tasks (missing dependencies)
5. Ask clarifying questions for unclear items

## Output Format

```markdown
# Plan Review: {plan-name}

## Summary
- Total tasks: N
- Ready: X
- Need clarification: Y
- Blocked: Z

## Task Analysis

### ✅ Ready Tasks
- Task 1: Clear description, measurable AC

### ⚠️ Needs Clarification
- Task 3: "Improve performance" - What metric? What target?
- Task 5: Missing acceptance criteria

### ❌ Blocked
- Task 7: Depends on Task 3 which is unclear

## Questions for User
1. What performance metric should Task 3 target?
2. What does "done" look like for Task 5?
```

## Usage

```
/ralph-review plans/260112-my-feature/
```
