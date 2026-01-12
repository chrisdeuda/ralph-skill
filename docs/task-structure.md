# Task File Structure

## Required Format

```markdown
# Feature Name

## Open Questions
<!-- RESOLVE BEFORE STARTING -->
- [ ] Q1: What API endpoint?
- [ ] Q2: Auth required?

## Phase 1: Prototype (Make It Work)
<!-- NO tests, NO lint -->

- [ ] Core implementation
  - **AC:** Basic functionality works

- [ ] CHECKPOINT: Manual verification
  - **AC:** Manually test the feature works
  - **PAUSE:** Stop here, verify before Phase 2

## Phase 2: Quality (After Verified)
<!-- ONLY after Phase 1 verified -->

- [ ] Add unit tests
- [ ] Add error handling
```

## Why This Structure

| Element | Purpose |
|---------|---------|
| Open Questions | Force clarification before coding |
| Phase 1 | Get working prototype fast |
| CHECKPOINT | Human verification gate |
| Phase 2 | Quality work on proven code |

## PRD Review

Run before implementation:
```bash
ralph-review plans/my-feature
```

Surfaces:
1. Unclear Requirements - Ambiguous tasks
2. Risk Points - What could waste time if wrong
3. Missing Phase Structure - If PRD jumps to tests

## Progress Logging

Append-only format (never overwrite):

```markdown
## Task N: [description]
**Status:** In Progress | **Time:** YYYY-MM-DD HH:MM

### Plan
- [step 1]

### Actions
- [HH:MM] Action taken
- [HH:MM] ERROR: What failed
- [HH:MM] RETRY: What tried instead

### Result
**Status:** Completed | **Completed:** HH:MM
```
