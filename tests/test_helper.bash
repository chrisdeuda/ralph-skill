#!/usr/bin/env bash

# Test helper for ralph-workflow.sh tests
# Provides shared setup and utilities for BATS tests

# Create temp dir and set PLAN_DIR before sourcing workflow
# (workflow requires PLAN_DIR at source time)
export TEST_TMPDIR=$(mktemp -d)
export PLAN_DIR="$TEST_TMPDIR"

# Create minimal plan files required by workflow
echo "- [ ] Test task" > "$TEST_TMPDIR/tasks.md"

# Source the workflow script
source "${BATS_TEST_DIRNAME}/../scripts/ralph-workflow.sh"

# Setup function (runs before each test)
setup() {
    # Reset temp dir for each test if needed
    export TEST_TMPDIR=$(mktemp -d)
}

# Teardown function (runs after each test)
teardown() {
    # Clean up temp directories
    [ -d "$TEST_TMPDIR" ] && rm -rf "$TEST_TMPDIR"
}
