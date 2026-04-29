---
name: "Playwright Smoke Test"
description: "Run Playwright UI smoke tests against the site, web, and portal apps"
on:
  workflow_dispatch:
    inputs:
      target_repo:
        description: 'Target repository (owner/repo)'
        required: false
        default: 'strawgate/o11yfleet'
        type: string
      base_url:
        description: 'Base URL for testing (leave empty for localhost dev)'
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
    allowed: [list_issues, create_issue]

safe-outputs:
  create-issue:
    title-prefix: "[playwright-smoke] "
    labels: [playwright, smoke-test, automated]
    max: 1
    close-older-key: "[playwright-smoke]"
    close-older-issues: true
    expires: 7d
    target-repo: ${{ inputs.target_repo }}

timeout-minutes: 120
---

Run Playwright UI smoke tests against o11yfleet and report any consistent failures as issues.

**Target Repository**: ${{ inputs.target_repo }}
**Base URL**: ${{ inputs.base_url || 'http://localhost:3000 (web app)' }}

## Setup

1. Checkout the target repository
2. Install dependencies: `pnpm install`
3. Install Playwright browsers: `pnpm playwright install chromium`
4. Start the API worker: `pnpm --filter @o11yfleet/worker dev &` (wait for port 8787)
5. Start the web app: `pnpm --filter @o11yfleet/web dev &` (wait for port 3000)

## Run Smoke Tests

Execute the Playwright UI smoke tests:

```bash
cd tests/ui
pnpm playwright test --reporter=list 2>&1 | tee /tmp/smoke-output.txt
```

Also run with trace collection on failure:
```bash
pnpm playwright test --trace on-first-retry 2>&1
```

## Analyze Results

1. Read `/tmp/smoke-output.txt` to understand test results
2. Check for:
   - Failed tests (consistent failures = real bugs)
   - Flaky tests (intermittent = environment issue)
   - Tests that errored (setup problem)
3. For failed tests, examine the failure reason carefully

## Issue Filing Criteria

**Only file an issue for consistent, real failures** — not flaky tests or environment issues.

### Quality Gate

Every finding must have:
1. **Exact test name and failure message** from Playwright output
2. **Evidence** — screenshot or trace if available in `tests/ui/test-results/`
3. **Actionable** — clear what needs to be fixed

### Issue Format

```
## Playwright Smoke Test Results

**Repository:** [target_repo]
**Run date:** [date]
**Test results:** [pass/fail counts]

### Failed Tests (Real Bugs)

| Test | Failure | Severity |
|------|---------|----------|
| [test name] | [error message] | [critical/high/medium] |

### Flaky Tests (Investigate Separately)

| Test | Pattern | Likely Cause |
|------|---------|--------------|
| [test name] | [intermittent pattern] | [guess] |

### Recommendations

- [ ] Fix critical failures first
- [ ] Stabilize flaky tests (likely async timing)
- [ ] Consider adding retries for environment-sensitive tests
```

If all tests pass or only flakiness found, call `noop`.