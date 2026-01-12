#!/usr/bin/env bash

# Test helper for ralph-workflow.sh tests
# Provides shared setup and utilities for BATS tests

# Source the main ralph-workflow.sh script
source "${BATS_TEST_DIRNAME}/../scripts/ralph-workflow.sh"

# Setup function (runs before each test)
setup() {
    # Create temp directories for testing if needed
    export TEST_TMPDIR=$(mktemp -d)
}

# Teardown function (runs after each test)
teardown() {
    # Clean up temp directories
    [ -d "$TEST_TMPDIR" ] && rm -rf "$TEST_TMPDIR"
}
