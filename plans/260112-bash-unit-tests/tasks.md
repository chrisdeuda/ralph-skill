# Add Unit Tests for Ralph Bash Scripts

## Open Questions
- [x] Q1: Which test framework? → BATS (Bash Automated Testing System)
- [x] Q2: What to test? → Functions in workflow, model detection, checkpoint detection

## Phase 1: Prototype (Make It Work)
<!-- NO full coverage, just prove testing works -->
<!-- Run: ralph-afk plans/260112-bash-unit-tests 5 auto prototype -->

- [x] Create ralph-kill script to cleanup Claude processes
  - **AC:** `ralph-kill` kills only Claude processes spawned by Ralph (tracks PIDs, not all claude)

- [ ] Install BATS testing framework
  - **AC:** `bats --version` works, test runner available

- [ ] Create test directory structure
  - **AC:** tests/ folder with test helper setup

- [ ] Write first test for detect_model()
  - **AC:** Test passes: "lint" → haiku, "debug" → opus, default → sonnet

- [ ] CHECKPOINT: Manual verification
  - **AC:** Run `bats tests/` and see passing tests
  - **PAUSE:** Verify test framework works before adding more tests

## Phase 2: Quality (After Verified)
<!-- Full test coverage -->
<!-- Run: ralph-afk plans/260112-bash-unit-tests 5 auto production -->

- [ ] Add tests for is_checkpoint()
  - **AC:** Tests: "CHECKPOINT" → yes, "manual verify" → yes, normal task → no

- [ ] Add tests for get_next_task()
  - **AC:** Tests: finds unchecked task, skips checked, returns empty when done

- [ ] Add tests for build_file_refs()
  - **AC:** Tests: includes CLAUDE.md, progress, tasks files

- [ ] Add tests for build_session_name()
  - **AC:** Tests: format "[Ralph] slug: T1 - preview"

- [ ] Add CI integration (GitHub Actions)
  - **AC:** Tests run on push to master

## Notes
<!-- Context for Ralph -->
- Scripts location: ~/.claude/skills/ralph/scripts/
- Main workflow: ralph-workflow.sh (has most functions)
- BATS docs: https://bats-core.readthedocs.io/
- Goal: Good foundation, don't break existing functionality
