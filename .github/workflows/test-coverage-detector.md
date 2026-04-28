---
name: "Test Coverage Detector"
description: "Find under-tested code paths and file actionable test coverage recommendations"
on:
  schedule:
    - cron: '0 17 * * 5'  # Fridays 5PM UTC
  workflow_dispatch:
    inputs:
      target_repo:
        description: 'Target repository (owner/repo)'
        required: false
        default: 'strawgate/agentic-workflows-playground'
        type: string
      severity:
        description: 'Minimum severity to report'
        required: false
        default: 'medium'
        type: choice
        options:
          - high
          - medium
          - low

permissions:
  contents: read
  issues: read
  pull-requests: read

github-app:
  client-id: ${{ vars.APP_ID }}
  private-key: ${{ secrets.APP_PRIVATE_KEY }}
  owner: "strawgate"
  repositories: ["*"]

engine:
  id: claude
  model: anthropic/claude-3-5-sonnet-20241022
  env:
    ANTHROPIC_BASE_URL: https://api.minimax.io/anthropic

tools:
  github:
    mode: remote
    allowed: [list_issues, create_issue]

safe-outputs:
  create-issue:
    title-prefix: "[test-coverage] "
    labels: [testing, automated]
    max: 1
    close-older-key: "[test-coverage]"
    close-older-issues: false
    expires: 7d
    target-repo: ${{ inputs.target_repo }}

timeout-minutes: 90
---

Identify under-tested code paths that would benefit from focused tests.

**Target Repository**: ${{ inputs.target_repo }}
**Severity Threshold**: ${{ inputs.severity }}

**The bar is high: most runs should end with `noop`.** Only file when you find concrete, high-value test gaps.

## Severity Policy

- **high** — Only untested critical paths: error handling, auth, data mutations, correctness-critical business logic
- **medium** — Everything in high, plus untested public APIs and recent changes lacking tests
- **low** — Everything in medium, plus minor but concrete coverage gaps with real user scenarios

## What to Look For

- **Untested public APIs**: exported functions, CLI commands, API endpoints with no/minimal coverage
- **Error paths**: exception handling, validation failures not exercised by tests
- **Recent changes without tests**: code modified in last 28 days without test updates
- **Critical business logic**: core algorithms, data transformations with insufficient coverage
- **Trace to user-facing behavior**: every gap should map to a concrete user action

## What to Skip

- Trivial getters, setters, simple constructors
- Generated code, vendored dependencies, third-party code
- Test files themselves
- Code paths adequately covered by integration/e2e tests
- Internal helpers only reachable through already-tested public APIs
- Subjective "should have more tests" without concrete scenario

## Issue Format

```
## Test Coverage Audit Summary

**Repository:** [target]
**Severity:** [threshold]
**Files audited:** [count]

### Critical Gaps

#### 1. [Function/File]
**What:** [description of untested path]
**User scenario:** [what user action reaches this]
**Recommended test:** [specific test to add]

### High Priority
...

## Recommended Actions
- [ ] Add test for [specific function]
```
