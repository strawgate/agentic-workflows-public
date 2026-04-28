---
name: "Code Quality Audit"
description: "Audit code for quality issues: complexity, duplication, dead code"
on:
  schedule:
    - cron: '0 14 * * 5'  # Fridays 2PM UTC
  workflow_dispatch:
    inputs:
      target_repo:
        description: 'Target repository (owner/repo)'
        required: false
        default: 'strawgate/agentic-workflows-playground'
        type: string
      file_filter:
        description: 'Glob pattern for files to audit (e.g., "**/*.go")'
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
    allowed: [list_issues, create_issue, list_pull_requests]

safe-outputs:
  create-issue:
    title-prefix: "[code-quality] "
    labels: [code-quality, automated]
    max: 1
    close-older-key: "[code-quality]"
    close-older-issues: false
    expires: 14d
    target-repo: ${{ inputs.target_repo }}

timeout-minutes: 90
---

Audit code for quality issues and file a consolidated report.

**Target Repository**: ${{ inputs.target_repo }}
**File Filter**: ${{ inputs.file_filter || 'all code files' }}

## Your Task

1. Explore the repository structure to understand the codebase
2. Focus on areas most likely to have quality issues:
   - Large files (>500 lines)
   - Deeply nested code (>4 levels)
   - Complex functions (high cyclomatic complexity)
   - Duplicate code blocks
   - Dead/unreachable code
   - TODO/FIXME comments left in code
3. Use `list_pull_requests` to check recent changes for context
4. Prioritize findings by impact and severity

## What to Look For

### High Priority
- Functions with no unit tests that should have them
- Error handling that's just `panic` or `log.Fatal`
- Hardcoded credentials or secrets
- SQL injection vulnerabilities
- Race conditions

### Medium Priority
- Functions longer than 100 lines
- Nested conditionals deeper than 3 levels
- Repeated identical code blocks (>3 occurrences)
- Unused functions or variables
- Missing error checks on external calls

### Low Priority
- Inconsistent naming conventions
- Missing comments on exported functions
- Improper error messages

## Issue Format

Create one consolidated issue with all findings:

```
## Code Quality Audit Summary

**Files audited:** [count]
**Issues found:** [count by severity]

### High Severity

#### 1. [Brief description]
**File:** [path]
**Problem:** [what is wrong]
**Impact:** [why it matters]

### Medium Severity

...

### Low Severity

...

## Recommended Actions

- [ ] [Actionable fix for each high-severity issue]
```

If no significant quality issues found, call `noop`.

(End of file - total 127 lines)