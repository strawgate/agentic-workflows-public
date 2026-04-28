---on:  schedule:    - cron: '0 2 * * 1-5'  # Weekdays 2AM UTC  workflow_dispatch:    inputs:      repos:        description: 'Comma-separated list of target repos'        required: false        default: 'strawgate/agentics'        type: string
engine: copilot
run-name: Daily status for ${{ inputs.repos }}
permissions:  contents: read
tools:  github:    mode: remote    toolsets: [repos, issues, pull_requests, actions]
safe-outputs:  github-token: ${{ secrets.GH_AW_READ_PAT }}  create-issue:    target-repo: ${{ vars.TARGET_REPO_GLOBAL }}    title-prefix: "[daily-status] "    labels: [automation, daily], completed   github-app:    client-id: ${{ vars.APP_ID }}    private-key: ${{ secrets.APP_PRIVATE_KEY }}    owner: strawgate-llc    repositories: [agentics]  create-issue:    target-repo: agentics    title-prefix: "[daily-status] "    max: 1---
# Daily Repository Status Workflow (SideRepoOps)
Generate daily status reports for repositories in your organization.
**Target Repositories**: ${{ inputs.repos }}
## Task
- Analyze recent activity (PRs, issues, releases, commits) in target repos
- Generate a daily status report summarizing key metrics and trends  
- Create issues in central tracking repo with actionable insights