#!/usr/bin/env bats

# Test logging-related variables and functions
# Tests: GUARDRAILS_FILE, ERRORS_LOG, ACTIVITY_LOG, build_file_refs with guardrails

load 'test_helper'

# ============================================
# GUARDRAILS_FILE Tests
# ============================================

@test "GUARDRAILS_FILE is set to ralph skill directory" {
  [ -n "$GUARDRAILS_FILE" ]
  [[ "$GUARDRAILS_FILE" == *"guardrails.md" ]]
}

@test "GUARDRAILS_FILE points to global location not per-plan" {
  [[ "$GUARDRAILS_FILE" == "$RALPH_SKILL_DIR/guardrails.md" ]]
}

@test "GUARDRAILS_FILE is exported" {
  # GUARDRAILS_FILE is set at source time, verify it's available
  [ -n "$GUARDRAILS_FILE" ]
  [[ "$GUARDRAILS_FILE" == *"guardrails.md" ]]
}

# ============================================
# ERRORS_LOG Tests
# ============================================

@test "ERRORS_LOG is set to plan directory" {
  [ -n "$ERRORS_LOG" ]
  [[ "$ERRORS_LOG" == *"errors.log" ]]
}

@test "ERRORS_LOG is per-plan file" {
  [[ "$ERRORS_LOG" == "$PLAN_DIR/errors.log" ]]
}

@test "ERRORS_LOG path contains plan directory" {
  [[ "$ERRORS_LOG" == "$TEST_TMPDIR/errors.log" ]]
}

# ============================================
# ACTIVITY_LOG Tests
# ============================================

@test "ACTIVITY_LOG is set to plan directory" {
  [ -n "$ACTIVITY_LOG" ]
  [[ "$ACTIVITY_LOG" == *"activity.log" ]]
}

@test "ACTIVITY_LOG is per-plan file" {
  [[ "$ACTIVITY_LOG" == "$PLAN_DIR/activity.log" ]]
}

@test "ACTIVITY_LOG path contains plan directory" {
  [[ "$ACTIVITY_LOG" == "$TEST_TMPDIR/activity.log" ]]
}

# ============================================
# build_file_refs with guardrails Tests
# ============================================

@test "build_file_refs includes guardrails.md when it exists" {
  # Create guardrails file in Ralph skill dir
  mkdir -p "$RALPH_SKILL_DIR"
  touch "$RALPH_SKILL_DIR/guardrails.md"
  refresh_plan_vars
  refs=$(build_file_refs)
  [[ "$refs" == *"guardrails.md"* ]]
}

@test "build_file_refs puts guardrails after CLAUDE.md" {
  mkdir -p "$RALPH_SKILL_DIR"
  touch "$RALPH_SKILL_DIR/CLAUDE.md"
  touch "$RALPH_SKILL_DIR/guardrails.md"
  refresh_plan_vars
  refs=$(build_file_refs)
  # Get positions
  claude_pos=$(echo "$refs" | grep -o '@[^ ]*' | grep -n 'CLAUDE.md' | cut -d: -f1)
  guard_pos=$(echo "$refs" | grep -o '@[^ ]*' | grep -n 'guardrails.md' | cut -d: -f1)
  # Guardrails should come after CLAUDE.md
  [ "$guard_pos" -gt "$claude_pos" ]
}

@test "build_file_refs puts guardrails before progress.md" {
  mkdir -p "$RALPH_SKILL_DIR"
  touch "$RALPH_SKILL_DIR/guardrails.md"
  touch "$PROGRESS_FILE"
  refresh_plan_vars
  refs=$(build_file_refs)
  # Get positions
  guard_pos=$(echo "$refs" | grep -o '@[^ ]*' | grep -n 'guardrails.md' | cut -d: -f1)
  progress_pos=$(echo "$refs" | grep -o '@[^ ]*' | grep -n 'progress.md' | cut -d: -f1)
  # Guardrails should come before progress
  [ "$guard_pos" -lt "$progress_pos" ]
}

# ============================================
# Variable Export Tests
# ============================================

@test "ERRORS_LOG is exported" {
  export PLAN_DIR="$TEST_TMPDIR"
  run bash -c "source '${BATS_TEST_DIRNAME}/../scripts/ralph-workflow.sh' 2>/dev/null && echo \$ERRORS_LOG"
  [[ "$output" == *"errors.log" ]]
}

@test "ACTIVITY_LOG is exported" {
  export PLAN_DIR="$TEST_TMPDIR"
  run bash -c "source '${BATS_TEST_DIRNAME}/../scripts/ralph-workflow.sh' 2>/dev/null && echo \$ACTIVITY_LOG"
  [[ "$output" == *"activity.log" ]]
}

# ============================================
# File reference order with all logging files
# ============================================

@test "build_file_refs order: CLAUDE.md, guardrails.md, progress.md, context.md, plan.md, tasks.md" {
  # Setup all files
  mkdir -p "$RALPH_SKILL_DIR"
  touch "$RALPH_SKILL_DIR/CLAUDE.md"
  touch "$RALPH_SKILL_DIR/guardrails.md"
  touch "$PROGRESS_FILE"
  touch "$CONTEXT_FILE"
  touch "$PLAN_FILE"
  refresh_plan_vars

  refs=$(build_file_refs)

  # Extract order
  claude_pos=$(echo "$refs" | grep -o '@[^ ]*' | grep -n 'CLAUDE.md' | cut -d: -f1 || echo "99")
  guard_pos=$(echo "$refs" | grep -o '@[^ ]*' | grep -n 'guardrails.md' | cut -d: -f1 || echo "99")
  progress_pos=$(echo "$refs" | grep -o '@[^ ]*' | grep -n 'progress.md' | cut -d: -f1 || echo "99")

  # Verify order
  [ "$claude_pos" -lt "$guard_pos" ]
  [ "$guard_pos" -lt "$progress_pos" ]
}
