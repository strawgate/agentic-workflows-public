---
name: "Text Auditor"
description: "Find typos, unclear error messages, and awkward user-facing text"
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
    title-prefix: "[text-auditor] "
    labels: [text, documentation, automated]
    max: 1
    close-older-key: "[text-auditor]"
    close-older-issues: false
    expires: 7d
    target-repo: ${{ inputs.target_repo }}

timeout-minutes: 90
---

Find typos, unclear error messages, and awkward user-facing text.

**Target Repository**: ${{ inputs.target_repo }}

**Only report concrete, unambiguous text problems.** `noop` is default when findings are uncertain.

## What to Look For

### Critical
- Typos in user-facing strings
- Error messages that don't describe the actual problem
- Messages that contradict actual behavior

### High Priority
- Inconsistent terminology for the same concept
- Unclear wording in help text
- Confusing CLI output

### Medium Priority
- Awkward sentence structure
- Grammar issues in user docs
- Inconsistent capitalization/punctuation

## What to Skip
- Typos in code comments (not user-facing)
- Style preferences without clarity impact
- Issues in generated/third-party code

## Issue Format

```
## Text Audit Report

**Repository:** [target]

### Typos

| File | Current | Suggested |
|------|---------|----------|
| [path] | [text] | [correction] |

### Unclear Text

#### 1. [File:Line]
**Current:** [text]
**Problem:** [why it's unclear]
**Suggested:** [clearer phrasing]

### Terminology Inconsistencies

| Term | Used For | Should Be |
|------|----------|-----------|
| [A] | [meaning 1], [meaning 2] | [standard meaning] |

### Recommended Actions
- [ ] Fix typo in [file]
- [ ] Clarify error message in [file]
```
