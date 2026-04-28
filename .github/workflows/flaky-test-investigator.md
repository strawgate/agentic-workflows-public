---
name: "Flaky Test Investigator"
description: "Investigate flaky tests from failed CI runs and file triage reports"
on:
  schedule:
    - cron: '0 10 * * *'  # Daily 10AM UTC
  workflow_dispatch:
    inputs:
      target_repo:
        description: 'Target repository (owner/repo)'
        required: false
        default: 'strawgate/agentic-workflows-playground'
        type: string

permissions:
  contents: read
  issues: read
  pull-requests: read
  actions: read

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
    toolsets: [default, actions]
    allowed: [list_issues, create_issue, list_workflow_runs]

safe-outputs:
  create-issue:
    title-prefix: "[flaky-test] "
    labels: [testing, flaky, automated]
    max: 1
    close-older-key: "[flaky-test]"
    close-older-issues: false
    expires: 7d
    target-repo: ${{ inputs.target_repo }}

timeout-minutes: 90
---

Investigate flaky tests from issues and failed CI runs.

**Target Repository**: ${{ inputs.target_repo }}

## Data Gathering

1. **Search for flaky test labels**: `flaky`, `flakey`, `intermittent`
2. **Inspect failed runs** from last 7 days
3. **Build frequency map** of repeated failing tests
4. **Check for duplicates**: existing triage issues, open PRs fixing same failure

## What to Look For

- Failures recurring across multiple runs/branches
- Same test failing with different stack traces
- Environment-sensitive failures (race, timeout, order)
- Retries/timeouts masking persistent defects

## Analysis Rules

- Only recommend fix with **clear root cause** and evidence — no hypotheses
- Retries, timeouts, quarantine are **not fixes** — don't recommend them
- Don't report one-off failures lacking repeat evidence
- Don't include items already tracked with sufficient detail

## Triage Reports

When root cause unclear but pattern exists (3+ occurrences):
- Document failure pattern (test, frequency, error signatures)
- List affected runs with links
- Provide ranked hypotheses
- Suggest concrete investigation steps

## Issue Format

```
## Flaky Test Investigation

**Repository:** [target]
**Period:** Last 7 days

### Repeated Failures

| Test | Occurrences | Error Pattern |
|------|-------------|---------------|
| [name] | [count] | [signature] |

### Root Cause Analysis

**[If identified:]**
[Explanation with evidence]

**[If unclear — triage needed:]**
**Hypotheses:**
1. [ranked by likelihood]
2.
3.

**Investigation Steps:**
- [ ] [concrete step]
```

Call `noop` if no repeated pattern (fewer than 3 occurrences).
