#!/usr/bin/env bats

# Test programmatic logging functions in ralph-utils.sh
# Tests: log_task_start, log_task_complete, log_iteration

load 'test_helper'

# Load ralph-utils.sh for logging functions
setup() {
    export TEST_TMPDIR=$(mktemp -d)
    export PLAN_DIR="$TEST_TMPDIR"
    mkdir -p "$TEST_TMPDIR"
    mkdir -p "$TEST_TMPDIR/../plans"  # For global log

    # Source the utils script
    source "${BATS_TEST_DIRNAME}/../scripts/ralph-utils.sh"
}

teardown() {
    [ -d "$TEST_TMPDIR" ] && rm -rf "$TEST_TMPDIR"
}

# ============================================
# log_task_start Tests
# ============================================

@test "log_task_start creates progress.md if not exists" {
    log_task_start "Test task" "sonnet" "production" "$TEST_TMPDIR" "test-plan"
    [ -f "$TEST_TMPDIR/progress.md" ]
}

@test "log_task_start creates plans/ralph-log.md if not exists" {
    log_task_start "Test task" "sonnet" "production" "$TEST_TMPDIR" "test-plan"
    [ -f "plans/ralph-log.md" ]
}

@test "log_task_start writes task title to progress.md" {
    log_task_start "Implement feature X" "sonnet" "production" "$TEST_TMPDIR" "test-plan"
    grep -q "Implement feature X" "$TEST_TMPDIR/progress.md"
}

@test "log_task_start writes model to progress.md" {
    log_task_start "Test task" "opus" "production" "$TEST_TMPDIR" "test-plan"
    grep -q "opus" "$TEST_TMPDIR/progress.md"
}

@test "log_task_start writes mode to progress.md" {
    log_task_start "Test task" "sonnet" "prototype" "$TEST_TMPDIR" "test-plan"
    grep -q "prototype" "$TEST_TMPDIR/progress.md"
}

@test "log_task_start writes plan name to progress.md" {
    log_task_start "Test task" "sonnet" "production" "$TEST_TMPDIR" "my-feature-plan"
    grep -q "my-feature-plan" "$TEST_TMPDIR/progress.md"
}

@test "log_task_start writes 'In Progress' status" {
    log_task_start "Test task" "sonnet" "production" "$TEST_TMPDIR" "test-plan"
    grep -q "In Progress" "$TEST_TMPDIR/progress.md"
}

@test "log_task_start truncates long task names at 60 chars" {
    long_task="This is a very long task description that should be truncated to sixty characters maximum"
    log_task_start "$long_task" "sonnet" "production" "$TEST_TMPDIR" "test-plan"
    # Should not contain the full string
    ! grep -q "maximum" "$TEST_TMPDIR/progress.md"
}

@test "log_task_start outputs console message" {
    run log_task_start "Test task" "sonnet" "production" "$TEST_TMPDIR" "test-plan"
    [[ "$output" == *"[LOG] Task started"* ]]
}

# ============================================
# log_task_complete Tests
# ============================================

@test "log_task_complete writes to progress.md" {
    echo "# Progress" > "$TEST_TMPDIR/progress.md"
    mkdir -p plans
    echo "# Log" > "plans/ralph-log.md"
    log_task_complete "Test task" "completed" "Task done" "$TEST_TMPDIR"
    grep -q "Result" "$TEST_TMPDIR/progress.md"
}

@test "log_task_complete shows completed status with checkmark" {
    echo "# Progress" > "$TEST_TMPDIR/progress.md"
    mkdir -p plans
    echo "# Log" > "plans/ralph-log.md"
    log_task_complete "Test task" "completed" "Task done" "$TEST_TMPDIR"
    grep -q "✅ Completed" "$TEST_TMPDIR/progress.md"
}

@test "log_task_complete shows blocked status with pause icon" {
    echo "# Progress" > "$TEST_TMPDIR/progress.md"
    mkdir -p plans
    echo "# Log" > "plans/ralph-log.md"
    log_task_complete "Test task" "blocked" "Checkpoint reached" "$TEST_TMPDIR"
    grep -q "⏸️ Blocked" "$TEST_TMPDIR/progress.md"
}

@test "log_task_complete shows error status with X icon" {
    echo "# Progress" > "$TEST_TMPDIR/progress.md"
    mkdir -p plans
    echo "# Log" > "plans/ralph-log.md"
    log_task_complete "Test task" "error" "Something failed" "$TEST_TMPDIR"
    grep -q "❌ Error" "$TEST_TMPDIR/progress.md"
}

@test "log_task_complete includes result message" {
    echo "# Progress" > "$TEST_TMPDIR/progress.md"
    mkdir -p plans
    echo "# Log" > "plans/ralph-log.md"
    log_task_complete "Test task" "completed" "Feature implemented successfully" "$TEST_TMPDIR"
    grep -q "Feature implemented successfully" "$TEST_TMPDIR/progress.md"
}

@test "log_task_complete outputs console message" {
    echo "# Progress" > "$TEST_TMPDIR/progress.md"
    mkdir -p plans
    echo "# Log" > "plans/ralph-log.md"
    run log_task_complete "Test task" "completed" "Done" "$TEST_TMPDIR"
    [[ "$output" == *"[LOG] Task completed"* ]]
}

# ============================================
# log_iteration Tests
# ============================================

@test "log_iteration writes iteration number to progress.md" {
    echo "# Progress" > "$TEST_TMPDIR/progress.md"
    log_iteration "3" "10" "Test task" "$TEST_TMPDIR"
    grep -q "3/10" "$TEST_TMPDIR/progress.md"
}

@test "log_iteration includes task description" {
    echo "# Progress" > "$TEST_TMPDIR/progress.md"
    log_iteration "1" "5" "Implement login" "$TEST_TMPDIR"
    grep -q "Implement login" "$TEST_TMPDIR/progress.md"
}

@test "log_iteration includes timestamp" {
    echo "# Progress" > "$TEST_TMPDIR/progress.md"
    log_iteration "2" "5" "Test task" "$TEST_TMPDIR"
    # Check for time format [HH:MM]
    grep -qE "\[[0-9]{2}:[0-9]{2}\]" "$TEST_TMPDIR/progress.md"
}

@test "log_iteration truncates long task names at 50 chars" {
    echo "# Progress" > "$TEST_TMPDIR/progress.md"
    long_task="This is a very long task description that exceeds fifty characters limit"
    log_iteration "1" "5" "$long_task" "$TEST_TMPDIR"
    # Should not contain the word "limit" (past 50 chars)
    ! grep -q "limit" "$TEST_TMPDIR/progress.md"
}

# ============================================
# Integration Tests
# ============================================

@test "log_task_start and log_task_complete create complete entry" {
    log_task_start "Build feature" "sonnet" "production" "$TEST_TMPDIR" "test-plan"
    log_task_complete "Build feature" "completed" "Feature built" "$TEST_TMPDIR"

    # Check both sections exist
    grep -q "In Progress" "$TEST_TMPDIR/progress.md"
    grep -q "✅ Completed" "$TEST_TMPDIR/progress.md"
}

@test "multiple log entries append correctly" {
    log_task_start "Task 1" "haiku" "prototype" "$TEST_TMPDIR" "test-plan"
    log_task_complete "Task 1" "completed" "Done" "$TEST_TMPDIR"
    log_task_start "Task 2" "sonnet" "prototype" "$TEST_TMPDIR" "test-plan"
    log_task_complete "Task 2" "completed" "Done" "$TEST_TMPDIR"

    # Count entries
    count=$(grep -c "In Progress" "$TEST_TMPDIR/progress.md")
    [ "$count" -eq 2 ]
}

@test "global log receives same entries as progress.md" {
    mkdir -p plans
    log_task_start "Test task" "sonnet" "production" "$TEST_TMPDIR" "test-plan"
    log_task_complete "Test task" "completed" "Done" "$TEST_TMPDIR"

    grep -q "In Progress" "plans/ralph-log.md"
    grep -q "✅ Completed" "plans/ralph-log.md"
}
