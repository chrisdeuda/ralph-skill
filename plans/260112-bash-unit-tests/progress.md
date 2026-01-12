# Progress: Add unit tests for Ralph bash scripts

Started: 2026-01-12 16:36

---

## [260112-bash-unit-tests] Task 1: Create ralph-kill script to cleanup Claude processes
**Status:** In Progress | **Time:** 2026-01-12 16:39 | **Model:** haiku | **Mode:** prototype

### Plan
- Create a script that kills all Claude processes spawned by Ralph
- Use ps to find processes with "claude" in the command
- Filter for processes that Ralph started (check for PLAN_DIR or similar markers)
- Output summary of killed processes
