# Key Learnings from Real Projects

## Case Study: safety365 SDS Label Preview

### What Happened

Ralph spent ~1 hour:
1. ✅ Building API, types, hooks, modal components
2. ✅ Writing E2E tests (5/5 passing)
3. ✅ Running code simplification
4. ❌ Manual test: **Wrong API calls**

Tests passed because they **mocked the API**. Actual API contract was wrong.

### Result

All test/lint/simplification work was wasted.

---

## Lesson 1: Tests Can Lie

> "5/5 E2E tests passing" means nothing if they mock the wrong API.

**Fix:** Manual verification before tests.

---

## Lesson 2: Lint is Not Validation

> "No lint errors" doesn't mean it works.

**Fix:** Working code first, clean code second.

---

## Lesson 3: Speed Over Perfection (Initially)

> "Get it working, then get it right."

**Fix:** Prototype mode exists for a reason.

---

## Lesson 4: Humans Catch What AI Misses

> "Only humans can verify 'this is what I wanted'"

**Fix:** CHECKPOINT exists because AI can't validate intent.

---

## Lesson 5: Clarify Before Building

> "Hours of coding to discover 'that's not what I meant'"

**Fix:** ralph-review surfaces unclear requirements early.

---

## The Pattern

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
