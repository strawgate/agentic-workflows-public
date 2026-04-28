---
name: "Newbie Contributor Patrol"
description: "Review docs from new contributor perspective and file blocking issues"
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
    allowed: [list_issues, create_issue]

safe-outputs:
  create-issue:
    title-prefix: "[newbie-contributor] "
    labels: [documentation, newcomer, automated]
    max: 1
    close-older-key: "[newbie-contributor]"
    close-older-issues: false
    expires: 7d
    target-repo: ${{ inputs.target_repo }}

timeout-minutes: 90
---

Review repository documentation from the perspective of an external contributor who knows the language/framework but is new to this project.

**Target Repository**: ${{ inputs.target_repo }}

Only file for **high-impact** gaps or blockers. Otherwise, report `noop`.

## What to Look For

- **Missing prerequisites**: setup steps that would block a new contributor
- **Inconsistent instructions**: conflicting info between docs
- **Non-existent paths**: commands or files that don't exist in fresh checkout
- **Undocumented requirements**: secrets, permissions, or roles needed but not documented
- **Unclear getting-started**: paths where contributor must guess between undocumented alternatives

## What to Skip

- Minor wording improvements
- Stylistic tweaks
- Optional clarifications
- Things clearly documented elsewhere

## Issue Format

```
## New Contributor Docs Review

**Repository:** [target]

### Blocking Issues

#### 1. [Brief description]
**Where:** [doc path + section]
**Problem:** [what's missing or incorrect]
**Impact:** [how this blocks new contributor]
**Suggested fix:** [specific change]

### Recommended Actions
- [ ] [Actionable fix for blocking issue]
```

If no blocking issues found, call `noop`.
