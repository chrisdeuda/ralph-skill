# Ralph Phases Explained

## Phase 1: Prototype (Make It Work)

**Purpose:** Prove core assumption works before investing in quality.

**Rules:**
- NO tests - they'd test wrong thing if API is wrong
- NO lint - polish comes later
- NO edge cases - just happy path
- YES console.log verification
- YES manual testing

**Mode:** `prototype`
```bash
ralph-afk plans/my-feature 5 auto prototype
```

---

## CHECKPOINT: Manual Verification

**Purpose:** Human confirms core functionality actually works.

**Why:**
- AI can write tests that pass but test wrong thing
- Mocked APIs hide integration bugs
- Only humans can verify "this is what I wanted"

**What happens:**
1. Ralph pauses automatically
2. Popup shows what to verify (from AC)
3. Human tests manually
4. Working → continue to Phase 2
5. Broken → fix and re-run Phase 1

---

## Phase 2: Quality (After Verified)

**Purpose:** Add quality work only to proven-working code.

**Includes:**
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

## Model Selection

| Task Type | Model | Cost | Reasoning |
|-----------|-------|------|-----------|
| lint, test, fix, docs | Haiku | $ | Mechanical, low creativity |
| implement, create, build | Sonnet | $$ | Balanced capability |
| debug, architect, refactor | Opus | $$$ | Needs deep reasoning |

Auto model selection saves 60-70% vs always using Opus.
