---
name: "UX Design Patrol"
description: "Detect UI/UX design drift and inconsistencies in recent changes"
on:
  workflow_dispatch:
    inputs:
      target_repo:
        description: 'Target repository (owner/repo)'
        required: false
        default: 'strawgate/agentic-workflows-playground'
        type: string
      lookback_window:
        description: 'Git lookback window'
        required: false
        default: '14 days ago'
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
    allowed: [list_issues, create_issue]

safe-outputs:
  create-issue:
    title-prefix: "[ux-design] "
    labels: [ux, design, automated]
    max: 1
    close-older-key: "[ux-design]"
    close-older-issues: true
    expires: 7d
    target-repo: ${{ inputs.target_repo }}

timeout-minutes: 90
---

Detect UX design drift — recent commits that introduce patterns duplicating or conflicting with established patterns.

**Target Repository**: ${{ inputs.target_repo }}
**Lookback**: ${{ inputs.lookback_window }}

**Noop is the expected outcome most days.** Only file when you find concrete, specific inconsistencies.

## What to Look For

1. **Output formatting**: new command prints differently than existing tables
2. **Confirmation dialogs**: different wording, ordering, or structure (`[y/N]` vs `[yes/no]`)
3. **CLI flags**: different naming conventions (`--dry-run` vs `--dryRun`)
4. **Status display**: different representation of enabled/disabled, active/inactive
5. **Help text**: different structure or tone than existing help
6. **Date/time formatting**: different format than established standard
7. **Color/icon usage**: different colors or symbols for same semantic meaning

## How to Analyze

1. Run `git log --since="$lookback_window" --oneline --stat`
2. For each commit, read full diff for user-facing patterns
3. Search for similar patterns elsewhere in codebase
4. Compare new pattern to existing ones

## What to Skip

- Internal implementation details
- Intentional different patterns (separate UI context)
- Trivial whitespace differences
- Changes that align with established patterns
- Cases where no existing pattern exists

## Issue Format

```
## UX Design Drift Report

**Repository:** [target]
**Period:** [lookback window]

### Inconsistencies Found

#### 1. [Pattern name]
**New:** [where introduced]
**Existing:** [where it exists]
**Problem:** [specific inconsistency]
**Consolidation approach:** [how to unify]

### Recommended Actions
- [ ] [Consolidate pattern X]
```
