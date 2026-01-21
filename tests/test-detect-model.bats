#!/usr/bin/env bats

load 'test_helper'

# Test detect_model() function
# This function selects the appropriate model based on task keywords
#
# Multi-provider model routing:
# - Implementation tasks (lint, test, fix, format, clean) → glm (cheap)
# - Planning/complex tasks (debug, architect, refactor) → opus
# - Default → sonnet

# === Implementation keywords (glm) ===

@test "detect_model returns glm for lint tasks" {
  result=$(detect_model "fix lint errors")
  [ "$result" = "glm" ]
}

@test "detect_model returns glm for test tasks" {
  result=$(detect_model "write unit tests")
  [ "$result" = "glm" ]
}

@test "detect_model returns glm for format tasks" {
  result=$(detect_model "format code")
  [ "$result" = "glm" ]
}

@test "detect_model returns glm for clean tasks" {
  result=$(detect_model "clean up temp files")
  [ "$result" = "glm" ]
}

# === Planning/complex keywords (opus) ===

@test "detect_model returns opus for debug tasks" {
  result=$(detect_model "debug memory leak")
  [ "$result" = "opus" ]
}

@test "detect_model returns opus for complex refactor tasks" {
  result=$(detect_model "refactor complex auth system")
  [ "$result" = "opus" ]
}

@test "detect_model returns opus for architect tasks" {
  result=$(detect_model "architect new API layer")
  [ "$result" = "opus" ]
}

# === Implementation keywords (formerly sonnet, now glm) ===

@test "detect_model returns glm for implement tasks" {
  result=$(detect_model "implement user profile page")
  [ "$result" = "glm" ]
}

@test "detect_model returns glm for add tasks" {
  result=$(detect_model "add dark mode support")
  [ "$result" = "glm" ]
}

@test "detect_model returns glm for update tasks" {
  result=$(detect_model "update documentation")
  [ "$result" = "glm" ]
}

# === Default (sonnet for unrecognized tasks) ===

@test "detect_model returns sonnet for unrecognized tasks" {
  result=$(detect_model "review the changes")
  [ "$result" = "sonnet" ]
}

# === Explicit provider tags ===

@test "detect_model returns glm for [GLM] tagged tasks" {
  result=$(detect_model "[GLM] implement feature")
  [ "$result" = "glm" ]
}

@test "detect_model returns opus for [OPUS] tagged tasks" {
  result=$(detect_model "[OPUS] analyze architecture")
  [ "$result" = "opus" ]
}

@test "detect_model returns sonnet for [SONNET] tagged tasks" {
  result=$(detect_model "[SONNET] review code")
  [ "$result" = "sonnet" ]
}

@test "detect_model returns sonnet for [CLAUDE] tagged tasks (alias)" {
  result=$(detect_model "[CLAUDE] review code")
  [ "$result" = "sonnet" ]
}
