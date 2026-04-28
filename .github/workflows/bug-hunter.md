---
name: "Bug Hunter"
description: "Find reproducible user-impacting bugs and file detailed reports"
on:
  schedule:
    - cron: '0 11 * * 1-5'  # Weekdays 11AM UTC
  workflow_dispatch:
    inputs:
      lookback_window:
        description: 'Git lookback window (e.g., "14 days ago")'
        required: false
        default: '28 days ago'
        type: string
      target_repo:
        description: 'Target repository (owner/repo)'
        required: false
        default: 'strawgate/agentic-workflows-playground'
        type: string

permissions:
  contents: read
  issues: read

engine:
  id: claude
  model: anthropic/claude-3-5-sonnet-20241022
  env:
    ANTHROPIC_BASE_URL: https://api.minimax.io/anthropic

tools:
  github:
    mode: remote
    allowed: [list_issues, create_issue, list_pull_requests]

safe-outputs:
  github-app:
    client-id: ${{ vars.APP_ID }}
    private-key: ${{ secrets.APP_PRIVATE_KEY }}
  create-issue:
    title-prefix: "[bug-hunter] "
    labels: [bug, automated]
    max: 1
    close-older-key: "[bug-hunter]"
    close-older-issues: true
    expires: 7d
    target-repo: ${{ inputs.target_repo }}

timeout-minutes: 90
---

Find a single reproducible, user-impacting bug and file a detailed report.

**Target Repository**: ${{ inputs.target_repo }}

**The bar is high: you must actually reproduce the bug before filing. Most runs should end with `noop`.**

## Data Gathering

1. Review recent changes:
   - Run `git log --since="${{ inputs.lookback_window }}" --stat` and identify candidates
   - Focus on user-facing changes: logic errors, incorrect conditionals, off-by-one errors
2. For each candidate, read the diff and related files

## What to Look For

- Logic errors: incorrect conditionals, wrong variables, missing edge-case handling
- Clear user impact: command failure, incorrect output, broken workflow
- Deterministic reproduction (not flaky)
- Can be expressed as a minimal failing test

## What to Skip

- Theoretical concerns without reproduction
- Test suite failures from running existing tests
- Edge cases requiring unusual inputs
- Already-tracked issues
- By-design behavior

## Reproduction (MANDATORY)

Do NOT file a bug without reproducing it:
1. Write a minimal reproduction script
2. Run it and capture the failure
3. If you cannot reproduce, do NOT file

## Issue Format

```
## Impact
[Who/what is affected, why it matters]

## Reproduction Steps
1. [Exact commands you ran]
2. [New test or script you wrote]

## Expected vs Actual
**Expected:** ...
**Actual:** ... [Include output]

## Failing Test
[The minimal reproduction code]
```

Call `create_issue` with the report, or `noop` if no bug found.