---
name: "Small Problem Fixer"
description: "Find small, clearly-scoped issues and open a focused PR to fix them"
on:
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
    toolsets: [default, pull_requests]
    allowed: [list_issues, create_issue, create_pull_request, search_code]

safe-outputs:
  create-issue:
    title-prefix: "[quick-fix] "
    labels: [quick-fix, automated]
    max: 1
    close-older-key: "[quick-fix]"
    close-older-issues: true
    expires: 3d
    target-repo: ${{ inputs.target_repo }}
  create-pull-request:
    max: 1
    target-repo: ${{ inputs.target_repo }}
    draft: true

timeout-minutes: 90
---

Find a small, clearly-scoped issue and open a focused PR that fixes it.

**Target Repository**: ${{ inputs.target_repo }}

**Most runs should end with `noop`.** Only open a PR when fix is clearly correct, tested, and small.

## Constraints

- Only one PR per run
- Fix must be small and obviously correct
- Skip issues needing design decisions or large refactors
- Skip issues with active discussion indicating complexity
- If no suitable issue found, call `noop`

## Candidate Discovery

1. Search for labeled issues: `good first issue`, `small`, `quick fix`, `easy`
2. Look for zero/low-comment issues (least recently updated)
3. Only consider `OWNER`, `MEMBER`, `COLLABORATOR` authored issues

## Selection Criteria

Prefer issues that:
- Are clearly actionable with small code change
- Have short reproduction steps
- Have no active discussion
- Are not duplicates of Bug Hunter issues

## Implementation

1. Locate relevant code
2. Make smallest safe change
3. Run relevant tests — **must pass**
4. If no tests exist for area, write minimal validation test
5. Commit locally

## Self-Review Before PR

- **Correctness**: Does fix actually address issue?
- **Scope**: Is change minimal?
- **Safety**: Could this break anything?
- **Reviewer experience**: Would maintainer approve quickly?

## Issue Format

If no fixable issue found:

```
No suitable small issue found. Repository appears well-maintained or issues require significant work.
```

If PR created:
- Link to PR in run summary
