#!/usr/bin/env bats

load 'test_helper'

# Test detect_model() function
# This function selects the appropriate model based on task keywords

@test "detect_model returns haiku for lint tasks" {
  result=$(detect_model "fix lint errors")
  [ "$result" = "haiku" ]
}

@test "detect_model returns haiku for test tasks" {
  result=$(detect_model "write unit tests")
  [ "$result" = "haiku" ]
}

@test "detect_model returns haiku for format tasks" {
  result=$(detect_model "format code")
  [ "$result" = "haiku" ]
}

@test "detect_model returns haiku for clean tasks" {
  result=$(detect_model "clean up temp files")
  [ "$result" = "haiku" ]
}

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

@test "detect_model returns sonnet for default tasks" {
  result=$(detect_model "implement user profile page")
  [ "$result" = "sonnet" ]
}

@test "detect_model returns sonnet for feature tasks" {
  result=$(detect_model "add dark mode support")
  [ "$result" = "sonnet" ]
}

@test "detect_model returns sonnet for generic tasks" {
  result=$(detect_model "update documentation")
  [ "$result" = "sonnet" ]
}
