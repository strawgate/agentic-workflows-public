---
on:
  schedule:
    - cron: '0 2 * * 1-5'  # Weekdays 2AM UTC
  workflow_dispatch:
    inputs:
      repos:
        description: 'Comma-separated list of target repos'
        required: false
        default: 'strawgate/agentic-workflows'
        type: string

permissions:
  contents: read
  issues: read
  pull-requests: read

engine:
  id: opencode
  version: 0.1.0
  model: anthropic/claude-3-5-sonnet-20241022
  env:
    ANTHROPIC_BASE_URL: https://api.minimax.io/anthropic

tools:
  github:
    mode: remote
    allowed: [list_issues, get_issue, create_issue, list_pull_requests, get_pull_request]

safe-outputs:
  github-app:
    client-id: ${{ vars.APP_ID }}
    private-key: ${{ secrets.APP_PRIVATE_KEY }}
  create-issue:
    title-prefix: "[daily-status] "
    labels: [automation, daily]
    max: 1

---

# Daily Repository Status Workflow (SideRepoOps with OpenCode + MiniMax)

Generate daily status reports for repositories in your organization using OpenCode with MiniMax Anthropic-compatible API.

**Target Repositories**: ${{ inputs.repos }}

## Task

- Analyze recent activity (PRs, issues, releases, commits) in target repos
- Generate a daily status report summarizing key metrics and trends
- Create issues in central tracking repo with actionable insights