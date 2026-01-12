# Test Logging Features

## Goal
Test that Ralph correctly writes to activity.log, errors.log, and guardrails.md

## Phase 1: Prototype

- [x] Create a simple hello.sh script in scripts/ that prints "Hello Ralph"
  - **AC:** File exists at scripts/hello.sh and is executable

- [x] Run the hello.sh script and verify output
  - **AC:** Script runs successfully, output shows "Hello Ralph"

- [x] Try to read a non-existent file to test error logging
  - **AC:** Error logged to errors.log with CAUSE and FIX

- [ ] CHECKPOINT: Verify logs are working
  - **AC:** activity.log has READ/EDIT/BASH entries, errors.log has the failed read
  - **PAUSE:** Manual verification of logging system

## Notes
- This is a test of the new logging system
- Watch: activity.log, errors.log, progress.md
