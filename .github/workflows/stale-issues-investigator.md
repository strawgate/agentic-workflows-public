---
name: "Stale Issues Investigator"
description: "Find open issues that appear resolved, label them, and file a report"
on:
  schedule:
    - cron: '0 9 * * 1'  # Mondays 9AM UTC
  workflow_dispatch:
    inputs:
      target_repo:
        description: 'Target repository (owner/repo)'
        required: false
        default: 'strawgate/agentic-workflows-playground'
        type: string
      stale_label:
        description: 'Label to apply to stale issues'
        required: false
        default: 'stale'
        type: string

permissions:
  contents: read
  issues: read

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
    title-prefix: "[stale-issues] "
    labels: [stale-issues, automated]
    max: 1
    close-older-key: "[stale-issues]"
    close-older-issues: true
    expires: 2d
    target-repo: ${{ inputs.target_repo }}
  add-labels:
    max: 10
    target-repo: ${{ inputs.target_repo }}

timeout-minutes: 60
---

Find open issues that are very likely already resolved and should be closed.

**Target Repository**: ${{ inputs.target_repo }}
**Stale Label**: ${{ inputs.stale_label }}

## How to Identify Stale Issues

1. **Build candidate set from oldest issues**
   - Start with issues not updated in 90+ days
   - Work toward newer if needed to find 10+ candidates

2. **For each candidate, check:**
   - Is there a merged PR that addresses this issue?
   - Has the described bug been fixed in a later version?
   - Has the feature been implemented?
   - Are there closed duplicates of this issue?
   - Does the issue title/description indicate it was completed?

3. **Evidence to collect:**
   - PR numbers that resolved the issue
   - Version/commits that fixed it
   - Related closed issues

## Skip Criteria
- Issues with `epic`, `tracking`, `umbrella` labels
- Issues with recent activity
- Issues where author responded recently
- Feature requests still relevant

## Issue Format

```
## Stale Issues Report

**Repository:** [target]
**Candidates found:** [count]

### Likely Resolved (apply stale label)

| # | Title | Last Updated | Evidence |
|---|-------|--------------|----------|
| 1 | [issue] | [date] | [PR #123, v2.0.1, duplicate #456] |

### Recommended Actions
- [ ] Label #XXX as stale
- [ ] Close #XXX (resolved by #PR)
```

If no stale issues found, call `noop`.
