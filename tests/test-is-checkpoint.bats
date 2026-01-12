#!/usr/bin/env bats

load 'test_helper'

# Test is_checkpoint() function
# This function detects if a task is a checkpoint task
# Checkpoints trigger pause for manual verification before proceeding

@test "is_checkpoint returns true for CHECKPOINT keyword" {
  is_checkpoint "CHECKPOINT: Manual Verification"
}

@test "is_checkpoint returns true for CHECKPOINT at start of line" {
  is_checkpoint "CHECKPOINT: verify workflow"
}

@test "is_checkpoint returns true for PAUSE: keyword" {
  is_checkpoint "PAUSE: verify tests pass"
}

@test "is_checkpoint returns true for manual verify phrase" {
  is_checkpoint "CHECKPOINT: manual verify before continuing"
}

@test "is_checkpoint returns true for manual test phrase" {
  is_checkpoint "CHECKPOINT: manual test the feature"
}

@test "is_checkpoint returns true for manual check phrase" {
  is_checkpoint "CHECKPOINT: manual check all tests"
}

@test "is_checkpoint returns true when manual verify is mid-string" {
  is_checkpoint "Phase 1 complete, manual verify required"
}

@test "is_checkpoint returns true when manual test is mid-string" {
  is_checkpoint "Please manual test the implementation"
}

@test "is_checkpoint returns true when manual check is mid-string" {
  is_checkpoint "Run manual check before deployment"
}

@test "is_checkpoint returns false for regular task" {
  ! is_checkpoint "Implement user authentication"
}

@test "is_checkpoint returns false for feature task" {
  ! is_checkpoint "Add dark mode support"
}

@test "is_checkpoint returns false for bug fix task" {
  ! is_checkpoint "Fix memory leak in handler"
}

@test "is_checkpoint returns false for generic task name" {
  ! is_checkpoint "Update documentation"
}

@test "is_checkpoint returns false for empty string" {
  ! is_checkpoint ""
}

@test "is_checkpoint returns false for whitespace only" {
  ! is_checkpoint "   "
}

@test "is_checkpoint returns false for verify without manual" {
  ! is_checkpoint "Verify implementation"
}

@test "is_checkpoint returns false for test without manual" {
  ! is_checkpoint "Run the tests"
}

@test "is_checkpoint is case-sensitive for CHECKPOINT" {
  # lowercase checkpoint should not match
  ! is_checkpoint "checkpoint: verify"
}

@test "is_checkpoint handles PAUSE with colon correctly" {
  is_checkpoint "PAUSE: take a break"
}

@test "is_checkpoint ignores leading whitespace before CHECKPOINT" {
  is_checkpoint "  CHECKPOINT: verify all"
}
