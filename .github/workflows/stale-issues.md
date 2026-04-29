---
name: "Stale Issue Detector"
description: "Detect and auto-comment on stale issues that need attention"
on:
  schedule:
    - cron: '0 12 * * 1-5'  # Weekdays 12PM UTC
  workflow_dispatch:
    inputs:
      target_repo:
        description: 'Target repository (owner/repo)'
        required: false
        default: 'strawgate/agentic-workflows-playground'
        type: string
      stale_days:
        description: 'Days without activity to be considered stale'
        required: false
        default: '14'
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
    allowed: [list_issues]

safe-outputs:
  add-comment:
    target-repo: ${{ inputs.target_repo }}
    max: 5
    discussions: false

timeout-minutes: 60
---

Find stale issues (no activity for {{ inputs.stale_days || 14 }} days) and add a comment asking if they're still relevant.

**Target Repository**: ${{ inputs.target_repo }}

1. Use `list_issues` to find open issues with no recent comments or updates
2. Calculate stale age based on `updated_at` timestamp
3. Add a friendly comment to each stale issue asking if it's still relevant
4. If no stale issues found, call `noop`

Call `add_comment` to post on stale issues, or `noop` if nothing stale.