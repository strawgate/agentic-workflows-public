---
name: "Code Duplication Detector"
description: "Find semantic duplicate code and refactoring opportunities"
on:
  schedule:
    - cron: '0 13 * * 5'  # Fridays 1PM UTC
  workflow_dispatch:
    inputs:
      target_repo:
        description: 'Target repository (owner/repo)'
        required: false
        default: 'strawgate/agentic-workflows-playground'
        type: string
      language:
        description: 'Language to analyze'
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
    title-prefix: "[duplication] "
    labels: [code-quality, automated]
    max: 1
    close-older-key: "[duplication]"
    close-older-issues: false
    expires: 7d
    target-repo: ${{ inputs.target_repo }}

timeout-minutes: 90
---

Find semantic duplicate code and refactoring opportunities.

**Target Repository**: ${{ inputs.target_repo }}
**Language**: ${{ inputs.language }}

## What to Look For

### High Priority (report these)
- Identical functions >10 lines in same module
- Similar functions handling same domain concept differently
- Copy-pasted validation logic
- Repeated error handling patterns

### Medium Priority
- Similar helper functions that could be consolidated
- Repeated string/formatting logic
- Duplicate configuration parsing
- Similar data transformations in different places

### Low Priority
- Minor repeated code blocks <5 lines
- Template repetition that could use generics

## What to Skip
- Tests (duplication there is sometimes intentional)
- Generated code
- Vendor/third-party code
- One-off scripts
- Different contexts where duplication is intentional

## Analysis Approach

1. Search for similar function signatures and names
2. Compare function bodies for semantic equivalence
3. Look for copy-paste indicators (comments, variable names)
4. Check if existing helper already exists but wasn't used

## Issue Format

```
## Code Duplication Report

**Repository:** [target]
**Language:** [language]

### Duplicates Found

#### 1. [Description]
**Locations:**
- [file:A:line]
- [file:B:line]
**Duplication type:** [identical|semantic|copy-paste]
**Suggested fix:** [consolidate into helper / use existing X]

### Recommended Actions
- [ ] Consolidate [pattern] into [location]
```
