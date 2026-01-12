#!/usr/bin/env bash

# Test helper for ralph-workflow.sh tests
# Provides shared setup and utilities for BATS tests

# Helper to refresh PLAN_DIR variables
refresh_plan_vars() {
    # Unset variables first to ensure clean slate
    unset TASK_SOURCE NEXT_TASK RALPH_MODEL FILE_REFS SESSION_NAME IS_CHECKPOINT
    unset PLAN_FILE CONTEXT_FILE PROGRESS_FILE TASKS_FILE GLOBAL_LOG PLAN_NAME

    # Re-source the workflow script to pick up current PLAN_DIR state
    source "${BATS_TEST_DIRNAME}/../scripts/ralph-workflow.sh" 2>/dev/null || true
}

# Setup function (runs before each test)
setup() {
    # Create new temp dir for this test
    export TEST_TMPDIR=$(mktemp -d)
    export PLAN_DIR="$TEST_TMPDIR"

    # Create minimal plan files required by workflow
    echo "- [ ] Test task" > "$TEST_TMPDIR/tasks.md"

    # Load the workflow script with proper variables
    refresh_plan_vars
}

# Teardown function (runs after each test)
teardown() {
    # Clean up temp directories
    [ -d "$TEST_TMPDIR" ] && rm -rf "$TEST_TMPDIR"
}
