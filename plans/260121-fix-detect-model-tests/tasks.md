# Fix detect_model Tests for Multi-Provider Support

## Context
The `detect_model()` function was updated to support multi-provider (CCS):
- Implementation tasks (lint, test, fix, format, clean) → `glm` (cheap)
- Planning/complex tasks (debug, architect, refactor) → `opus`
- Default → `sonnet`

Tests in `tests/test-detect-model.bats` are outdated - they expect old behavior (haiku).

## Tasks

### [GLM] ~~Task 1: Update haiku tests to expect glm~~ ✅
**File**: `tests/test-detect-model.bats`

Update these tests to expect `glm` instead of `haiku`:
- "detect_model returns haiku for lint tasks" → expect `glm`
- "detect_model returns haiku for test tasks" → expect `glm`
- "detect_model returns haiku for format tasks" → expect `glm`
- "detect_model returns haiku for clean tasks" → expect `glm`

Also rename test descriptions from "haiku" to "glm".

---

### [GLM] ~~Task 2: Update sonnet tests to expect glm~~ ✅
**File**: `tests/test-detect-model.bats`

These tasks contain keywords that now route to `glm`:
- "implement user profile page" contains "implement" → `glm`
- "add dark mode support" contains "add" → `glm`
- "update documentation" contains "update" → `glm`

Update tests to expect `glm` instead of `sonnet`.

---

### [GLM] ~~Task 3: Add new test for sonnet default~~ ✅
**File**: `tests/test-detect-model.bats`

Add a test that actually returns `sonnet` (no matching keywords):
```bash
@test "detect_model returns sonnet for unrecognized tasks" {
  result=$(detect_model "review the changes")
  [ "$result" = "sonnet" ]
}
```

---

### [GLM] ~~Task 4: Add explicit tag tests~~ ✅
**File**: `tests/test-detect-model.bats`

Add tests for explicit provider tags:
```bash
@test "detect_model returns glm for [GLM] tagged tasks" {
  result=$(detect_model "[GLM] implement feature")
  [ "$result" = "glm" ]
}

@test "detect_model returns opus for [OPUS] tagged tasks" {
  result=$(detect_model "[OPUS] analyze architecture")
  [ "$result" = "opus" ]
}

@test "detect_model returns sonnet for [SONNET] tagged tasks" {
  result=$(detect_model "[SONNET] review code")
  [ "$result" = "sonnet" ]
}
```

---

### [GLM] ~~Task 5: Run tests and verify all pass~~ ✅
Run: `bats tests/test-detect-model.bats`

All tests should pass.

## Acceptance Criteria
- [x] No tests expect `haiku` (removed from multi-provider)
- [x] Implementation keywords (lint, test, fix, etc.) expect `glm`
- [x] Planning keywords (debug, architect) expect `opus`
- [x] Default/unrecognized expects `sonnet`
- [x] Explicit tags `[GLM]`, `[OPUS]`, `[SONNET]` work
- [x] All tests pass (15/15)
