---
name: "Breaking Change Detector"
description: "Detect undocumented breaking changes in public interfaces"
on:
  schedule:
    - cron: '0 15 * * 1-5'  # Weekdays 3PM UTC
  workflow_dispatch:
    inputs:
      target_repo:
        description: 'Target repository (owner/repo)'
        required: false
        default: 'strawgate/agentic-workflows-playground'
        type: string
      lookback_days:
        description: 'Days to look back for changes (default: 3 for Monday, 1 otherwise)'
        required: false
        default: ''
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
    allowed: [list_issues, create_issue, list_pull_requests, search_pull_requests]

safe-outputs:
  create-issue:
    title-prefix: "[breaking-change] "
    labels: [breaking-change, automated]
    max: 1
    close-older-key: "[breaking-change]"
    close-older-issues: false
    expires: 7d
    target-repo: ${{ inputs.target_repo }}

timeout-minutes: 90
---

Detect undocumented breaking changes in public interfaces.

**Target Repository**: ${{ inputs.target_repo }}

## Your Task

1. Run `git log --since="<lookback>" --oneline --stat` to get recent commits
2. For each significant commit:
   - Review the diff to understand what changed
   - Look for: removed/renamed files, API changes, workflow changes, dependency updates
   - Check if the PR body or comments document the change
3. Focus on changes that would break downstream consumers:
   - Workflow interface changes (inputs, outputs, triggers)
   - API/CLI changes (removed flags, changed behavior)
   - Dependency version bumps that break compatibility
4. If changes are documented in CHANGELOG, release notes, or PR, they're not "undocumented"

## What to Look For

**Breaking changes include:**
- Removed or renamed public APIs, functions, CLI flags
- Changed default values that affect behavior
- Breaking refactors (changing return types, removing fields)
- Dependency updates that break plugins or extensions
- Workflow changes that break existing CI/CD pipelines

**NOT breaking changes:**
- Internal refactors with no public impact
- Additive changes (new optional parameters with defaults)
- Bug fixes that were previously broken
- Documentation updates

## Quality Gate

**Noop is expected most days.** Only file an issue when you can show:
1. A specific interface contract was broken
2. Downstream consumers would fail or get wrong results
3. The break is NOT documented anywhere

If in doubt, noop.

## Issue Format

```
## Breaking Changes Detected

### 1. [Brief description]
**Commit:** [SHA]
**What broke:** [Specific change that breaks compatibility]
**Impact:** [How downstream consumers are affected]
**Suggested fix:** [How to document or migrate]

## Suggested Actions
- [ ] Document the breaking change
- [ ] Add migration guidance
```

If no undocumented breaking changes found, call `noop`.

(End of file - total 123 lines)