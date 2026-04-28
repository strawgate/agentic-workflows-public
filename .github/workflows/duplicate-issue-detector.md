---
name: "Duplicate Issue Detector"
description: "Detect potential duplicate issues and suggest links"
on:
  schedule:
    - cron: '0 13 * * 1-5'  # Weekdays 1PM UTC
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
    allowed: [list_issues]

safe-outputs:
  add-comment:
    target-repo: ${{ inputs.target_repo }}
    max: 10
    discussions: false

timeout-minutes: 60
---

Find potential duplicate issues in the repository and suggest links to reporters.

**Target Repository**: ${{ inputs.target_repo }}

## Your Task

1. Use `list_issues` to fetch all open issues (paginate through all pages)
2. For each pair of issues, analyze:
   - Title similarity (exact phrases, keywords)
   - Body similarity (same error messages, stack traces, or reproduction steps)
   - Label overlap (if labels indicate the same bug/feature area)
   - Time proximity (same issue reported within a short window)
3. Group issues that appear to be duplicates
4. For each group of potential duplicates:
   - Add a comment to the newer issue suggesting it may be duplicate of the older one
   - Include a brief explanation of why they appear related
5. If no duplicates found, call `noop`

## Duplicate Detection Criteria

Consider issues duplicates if they share:
- Same error message or stack trace pattern
- Same root cause (even with different wording)
- Same file/function/component affected
- Same workaround or fix mentioned
- Filed within 7 days of each other with similar content

## Comment Format

```markdown
This issue appears similar to #[ISSUE_NUMBER] - they may be duplicates.

**Similarity indicators:**
- [Brief explanation of what makes them similar]

Please confirm if these are the same issue, and if so, we can close this one as a duplicate.
```

(End of file - total 73 lines)