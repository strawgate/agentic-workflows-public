---
name: "Playwright Accessibility Audit"
description: "Run axe-core accessibility tests across all portal pages and report violations"
on:
  schedule:
    - cron: '0 14 * * 5'  # Fridays 2PM UTC
  workflow_dispatch:
    inputs:
      target_repo:
        description: 'Target repository (owner/repo)'
        required: false
        default: 'strawgate/o11yfleet'
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
    title-prefix: "[a11y] "
    labels: [accessibility, axe-core, automated]
    max: 1
    close-older-key: "[a11y]"
    close-older-issues: true
    expires: 14d
    target-repo: ${{ inputs.target_repo }}

timeout-minutes: 120
---

{{#include .github/workflows/gh-aw-fragments/rigor.md}}

{{#include .github/workflows/gh-aw-fragments/previous-findings.md}}

Audit o11yfleet portal pages for accessibility violations using axe-core.

**Target Repository**: ${{ inputs.target_repo }}

## Your Mission

**Explore BEYOND the pages listed below.** The pages below are your *starting point* — not an exhaustive list. After auditing these, you MUST:
1. Look at the app's routing configuration to find ALL routes
2. Navigate to any pages not explicitly listed
3. Check authenticated pages (log in first, then audit)
4. Explore dynamic routes (e.g., `/portal/agents/:id`, `/admin/tenants/:id`)

Your goal is comprehensive a11y coverage. Following only this script leaves half the app unchecked.

## Pages to Audit (Starting Point)

### Marketing & Auth
- `/` (homepage)
- `/about`, `/pricing`
- `/login`, `/admin-login`

### User Portal (after logging in)
- `/portal/overview`
- `/portal/agents`
- `/portal/configurations`
- `/portal/builder`
- `/portal/settings`

### Admin Portal (after admin login)
- `/admin/overview`
- `/admin/tenants`
- `/admin/health`
- `/admin/events`

## Discovery Steps

After auditing the pages above, you MUST:
1. Read routing config to find ALL routes
2. Audit any routes not yet checked
3. Explore authenticated flows (login and audit protected pages)
4. Check dynamic routes with IDs

## Setup

1. Checkout the target repository
2. Install dependencies: `pnpm install`
3. Install Playwright + browsers: `pnpm playwright install --with-deps chromium`
4. Start API worker: `pnpm --filter @o11yfleet/worker dev &`
5. Start web app: `pnpm --filter @o11yfleet/web dev &`
6. Wait for servers to be ready (check ports 8787 and 3000)

## Run Accessibility Audit

### Option A: If axe-core is already integrated

```bash
cd tests/ui
pnpm playwright test --grep "a11y\|accessibility" --reporter=list 2>&1 | tee /tmp/a11y-output.txt
```

### Option B: Quick audit script

Create and run a dedicated a11y test script:

```bash
cat > /tmp/a11y-audit.js << 'EOF'
const { chromium } = require('@playwright/test');
const AxeBuilder = require('@axe-core/playwright').default;

const PAGES = [
  { name: 'Homepage', path: '/' },
  { name: 'Login', path: '/login' },
  { name: 'Portal Overview', path: '/portal/overview' },
  { name: 'Admin Overview', path: '/admin/overview' },
  // ... add more pages
];

(async () => {
  const browser = await chromium.launch();
  const context = await browser.newContext();
  const page = await context.newPage();
  
  const results = [];
  
  for (const { name, path } of PAGES) {
    try {
      await page.goto(`http://localhost:3000${path}`, { waitUntil: 'networkidle' });
      const result = await new AxeBuilder({ page })
        .withTags(['wcag2a', 'wcag2aa', 'wcag21aa'])
        .analyze();
      results.push({ page: name, path, violations: result.violations });
    } catch (e) {
      results.push({ page: name, path, error: e.message });
    }
  }
  
  console.log(JSON.stringify(results, null, 2));
  await browser.close();
})();
EOF
node /tmp/a11y-audit.js 2>&1 | tee /tmp/a11y-results.json
```

## Analyze Results

1. Read the axe-core violation report
2. For each violation, note:
   - **Element selector** causing the violation
   - **WCAG criterion** (e.g., "color-contrast", "aria-required-attr")
   - **Impact level** (critical, serious, moderate, minor)
   - **Help text** from axe

3. Check for common o11yfleet patterns:
   - `color-contrast` violations on dark mode text
   - Missing `aria-label` on icon-only buttons
   - `page-has-heading-one` on pages without proper h1
   - Form inputs without associated labels

## Issue Output Format

Create one consolidated issue if violations found:

```
## Accessibility Audit Summary

**Repository:** [target_repo]
**Audit date:** [date]
**Pages audited:** [count]
**Total violations:** [count by severity]

### Critical Severity (Must Fix)

| Page | Violation | WCAG | Element |
|------|-----------|------|---------|
| [page] | [description] | [criterion] | [selector] |

### Serious Severity

...

### Moderate/Minor

...

## Recommended Fixes

For each violation, provide:
1. The specific CSS selector or element
2. The WCAG criterion it violates
3. Suggested fix (e.g., "Add aria-label='Close menu' to button")

## Accessibility Baseline

Create a baseline file (like `tests/ui/a11y-baseline.json`) to track known violations
and prevent regressions. New violations should fail the audit.
```

If no violations found, call `noop`.