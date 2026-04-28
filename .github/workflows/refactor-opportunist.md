---
name: "Refactor Opportunist"
description: "Find high-impact structural refactoring opportunities and partially implement to prove viability"
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
    allowed: [list_issues, create_issue, search_code, list_pull_requests]

safe-outputs:
  create-issue:
    title-prefix: "[refactor] "
    labels: [refactor, automated]
    max: 1
    close-older-key: "[refactor]"
    close-older-issues: true
    expires: 14d
    target-repo: ${{ inputs.target_repo }}

timeout-minutes: 90
---

Identify **one** structural improvement (refactor, reorganization, or architectural simplification) that would meaningfully improve the codebase — and then **partially implement it** to prove viability before pitching it.

**Target Repository**: ${{ inputs.target_repo }}

**The bar is high.** Most runs should end with `noop`. Only propose a refactor when you have concrete evidence of a structural problem and have verified the approach works.

## Data Gathering

1. **Understand the architecture**
   - Read `README.md`, `CONTRIBUTING.md`, `DEVELOPING.md`, and any architecture docs
   - Map out the high-level module structure

2. **Identify structural pain points**
   - Look for: tangled dependencies, duplicated patterns, inconsistent abstractions, overly complex indirection
   - Review `git log --since="60 days ago" --stat` for frequently-changing files
   - Check recent PRs and issues for complaints about code being "hard to change" or "duplicated"

3. **Select one refactor target**
   - Choose the highest-impact structural improvement
   - Must be decomposable — implementable incrementally
   - Use a prioritization score:
     - Impact on maintainability (0-3)
     - Incremental viability (0-3)
     - Evidence strength (0-2)
     - Reuse bonus if existing helper exists (0-2)

## Analysis and Partial Implementation

4. **Partially implement to prove viability**
   - Implement the refactor for **one representative slice**
   - Run build/lint/test commands to verify it compiles and tests pass
   - If partial implementation fails, call `noop`

5. **Capture the proof-of-concept**
   - Record exact changes (file paths, before/after snippets)
   - Record which commands ran and their results

## Noop Criteria

Call `noop` if:
- No structural issue is significant enough
- Best candidate overlaps with existing open issue/PR
- Partial implementation failed
- Refactor cannot be done incrementally
- Improvement is cosmetic rather than structural

## Issue Format

```
## Refactor Proposal: [Short Description]

### Problem
[Structural issue identified]

### Evidence
[Code evidence, churn data, or issue references]

### Proposed Approach
[How to refactor incrementally]

### Proof of Viability
[What was partially implemented and results]

### Recommended Actions
- [ ] [Actionable steps for maintainers]
```
