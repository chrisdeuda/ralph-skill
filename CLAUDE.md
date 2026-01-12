# Ralph Design Philosophy

This document explains the design decisions behind Ralph's workflow. **Read this before every task** to understand why the workflow is structured this way.

---

## Core Principle: Validate First, Polish Later

> "All that quality work was wasted because the core assumption was wrong."

### The Problem We Solved

In a real project (safety365 SDS Label Preview), Ralph spent ~1 hour:
1. ✅ Building API, types, hooks, modal components
2. ✅ Writing E2E tests (5/5 passing)
3. ✅ Running code simplification
4. ❌ Manual test revealed: **Wrong API calls**

The tests passed because they **mocked the API**. But the actual API contract was wrong. All test/lint/simplification work was wasted.

### The Solution: Prototype → Checkpoint → Quality

```
OLD (Broken):
  Build → Test → Manual verify
  ↳ Tests pass but API wrong
  ↳ Wasted hours on tests for broken code

NEW (Fixed):
  Build → CHECKPOINT → Manual verify → Test
  ↳ Catch API issues early
  ↳ Tests only written for working code
```

---

## Why Phases Matter

### Phase 1: Prototype (Make It Work)

**Purpose:** Prove the core assumption works before investing in quality.

**Rules:**
- NO tests - they'd test the wrong thing if API is wrong
- NO lint - polish comes later
- NO edge cases - just happy path
- YES console.log verification
- YES manual testing

**Mode:** `prototype`
```bash
ralph-afk plans/my-feature 5 auto prototype
```

### CHECKPOINT: Manual Verification

**Purpose:** Human confirms the core functionality actually works.

**Why it exists:**
- AI can write tests that pass but test the wrong thing
- Mocked APIs hide integration bugs
- Only humans can verify "this is what I wanted"

**What happens:**
1. Ralph pauses automatically
2. Popup shows what to verify (from AC)
3. Human tests manually
4. If working → continue to Phase 2
5. If broken → fix and re-run Phase 1

### Phase 2: Quality (Polish After Verified)

**Purpose:** Add quality work only to code that's proven to work.

**What's included:**
- Unit tests (now testing correct behavior)
- E2E tests
- Error handling
- Edge cases
- Code simplification
- Lint fixes

**Mode:** `production`
```bash
ralph-afk plans/my-feature 5 auto production
```

---

## Why PRD Review Exists

### The Problem

Ralph would start implementing immediately without questioning unclear requirements:
- "What API endpoint?" - Ralph guesses
- "Auth required?" - Ralph assumes
- "Expected response shape?" - Ralph invents

Hours later: "That's not what I meant"

### The Solution: ralph-review

Run before implementation to surface:
1. **Unclear Requirements** - Ambiguous tasks
2. **Risk Points** - What could waste time if wrong
3. **Missing Phase Structure** - If PRD jumps to tests

```bash
ralph-review plans/my-feature
```

---

## Task File Structure

### Required Format

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

### Why This Structure

| Element | Purpose |
|---------|---------|
| Open Questions | Force clarification before coding |
| Phase 1 | Get working prototype fast |
| CHECKPOINT | Human verification gate |
| Phase 2 | Quality work on proven code |

---

## Model Selection Philosophy

### Why Auto-Select Models

Different tasks need different capabilities:

| Task Type | Model | Cost | Reasoning |
|-----------|-------|------|-----------|
| lint, test, fix, docs | Haiku | $ | Mechanical, low creativity |
| implement, create, build | Sonnet | $$ | Balanced capability |
| debug, architect, refactor | Opus | $$$ | Needs deep reasoning |

### Cost Savings

Auto model selection saves 60-70% compared to always using Opus.

---

## Append-Only Logging

### Why Never Overwrite progress.md

1. **Debugging:** See what was tried and failed
2. **Learning:** Understand Ralph's decision process
3. **Audit:** Track what changed and when
4. **Recovery:** If something breaks, see history

### Log Format

```markdown
## Task N: [description]
**Status:** In Progress | **Time:** YYYY-MM-DD HH:MM

### Plan
- [step 1]
- [step 2]

### Actions
- [HH:MM] Action taken
- [HH:MM] ERROR: What failed
- [HH:MM] RETRY: What tried instead

### Result
**Status:** Completed | **Completed:** HH:MM
```

---

## Key Learnings (From Real Projects)

### 1. Tests Can Lie

> "5/5 E2E tests passing" means nothing if they mock the wrong API.

**Lesson:** Manual verification before tests.

### 2. Lint is Not Validation

> "No lint errors" doesn't mean it works.

**Lesson:** Working code first, clean code second.

### 3. Speed Over Perfection (Initially)

> "Get it working, then get it right."

**Lesson:** Prototype mode exists for a reason.

### 4. Humans Catch What AI Misses

> "Only humans can verify 'this is what I wanted'"

**Lesson:** CHECKPOINT exists because AI can't validate intent.

### 5. Clarify Before Building

> "Hours of coding to discover 'that's not what I meant'"

**Lesson:** ralph-review surfaces unclear requirements early.

---

## Commands Reference

```bash
# Initialize plan with prototype-first structure
ralph-init my-feature

# Review PRD for unclear requirements
ralph-review plans/260112-my-feature

# Run prototype phase (no tests, no lint)
ralph-afk plans/260112-my-feature 5 auto prototype

# After manual verification, run quality phase
ralph-afk plans/260112-my-feature 5 auto production

# Single iteration (HITL mode)
ralph-once plans/260112-my-feature sonnet prototype

# Check status across all plans
ralph-status
```

---

## Summary

| Principle | Implementation |
|-----------|----------------|
| Validate before polish | Prototype → Checkpoint → Quality |
| Clarify before build | ralph-review surfaces unclear requirements |
| Human verification gate | CHECKPOINT pauses for manual testing |
| Tests after validation | Phase 2 only runs after Phase 1 verified |
| Right model for task | Auto-select haiku/sonnet/opus |
| Audit trail | Append-only progress.md logging |
