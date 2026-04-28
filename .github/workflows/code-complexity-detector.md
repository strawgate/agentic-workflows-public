---
name: "Code Complexity Detector"
description: "Find overly complex code and propose simplification opportunities"
on:
  schedule:
    - cron: '0 12 * * 5'  # Fridays noon UTC
  workflow_dispatch:
    inputs:
      target_repo:
        description: 'Target repository (owner/repo)'
        required: false
        default: 'strawgate/agentic-workflows-playground'
        type: string
      language:
        description: 'Primary language to analyze'
        required: false
        default: 'rust'
        type: choice
        options:
          - rust
          - typescript
          - go
          - python

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
    title-prefix: "[complexity] "
    labels: [code-quality, automated]
    max: 1
    close-older-key: "[complexity]"
    close-older-issues: false
    expires: 7d
    target-repo: ${{ inputs.target_repo }}

timeout-minutes: 90
---

Find overly complex code and file a simplification report.

**Target Repository**: ${{ inputs.target_repo }}
**Language**: ${{ inputs.language }}

## What to Look For

### High Priority
- Functions >100 lines doing multiple things
- Nested conditionals >3 levels deep
- Classes/modules with >10 public methods
- Functions with >5 parameters
- Cyclomatic complexity >10

### Medium Priority
- Functions 50-100 lines that could be split
- Repeated switch/match statements over same enum
- Long parameter lists that could be grouped into structs
- Complex boolean expressions that could be named

### Low Priority
- Magic numbers/strings that should be constants
- Overly clever one-liners hard to read
- Missing early returns making logic hard to follow

## What to Skip
- Tests (complexity there is sometimes necessary)
- Generated code
- One-off scripts
- Vendor/third-party code

## Issue Format

```
## Code Complexity Report

**Repository:** [target]
**Language:** [language]

### Complex Functions

#### 1. [File:Function] (lines X-Y)
**Problem:** [what makes it complex]
**Suggestion:** [how to simplify]
**Impact:** [why this matters]

### Recommended Actions
- [ ] Simplify [function] — [specific approach]
```
