---
name: "Playwright Love Audit"
description: "Comprehensive UX audit - screenshot every page, capture ARIA snapshots, analyze for papercuts"
on:
  schedule:
    - cron: '0 15 * * 3'  # Wednesdays 3PM UTC
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
    title-prefix: "[love] "
    labels: [ux, papercuts, automated]
    max: 1
    close-older-key: "[love]"
    close-older-issues: true
    expires: 14d
    target-repo: ${{ inputs.target_repo }}

timeout-minutes: 180
---

{{#include .github/workflows/gh-aw-fragments/rigor.md}}

{{#include .github/workflows/gh-aw-fragments/previous-findings.md}}

You are a meticulous UI quality auditor who boots the app, navigates every page with realistic data, and hunts for paper cuts, rough edges, and things that could use polish.

**Target Repository**: ${{ inputs.target_repo }}

## Your Mission

**Explore BEYOND the pages listed below.** The pages below are your *starting point* — not an exhaustive list. After auditing these, you MUST:
1. Look at the app's routing configuration to find ALL routes
2. Navigate to any pages not explicitly listed
3. Try clicking through the UI to discover hidden or dynamic pages
4. Check for pages that require authentication that you can access
5. Look for pages linked from navigation, breadcrumbs, and sidebars

Your goal is to find genuine UX issues. If you only follow the script without exploring, you'll miss half the app.

## Pages to Audit (Starting Point)

### Site App (Marketing + Portal + Admin) — http://localhost:4000

**Auth:**
- `/login` - User login
- `/admin-login` - Admin login

**Marketing:**
- `/` - Homepage
- `/about` - About page
- `/pricing` - Pricing page

**User Portal:**
- `/portal/overview` - Dashboard overview
- `/portal/agents` - Agent list
- `/portal/configurations` - Config list
- `/portal/builder` - Config builder
- `/portal/getting-started` - Onboarding
- `/portal/settings` - User settings

**Admin Portal:**
- `/admin/overview` - Admin dashboard
- `/admin/tenants` - Tenant management
- `/admin/health` - System health
- `/admin/events` - Event log

### Web App (Alternative UI) — http://localhost:3000

**Auth:**
- `/login`, `/admin-login`

**Portal:**
- `/portal/overview`, `/portal/agents`, `/portal/configurations`, `/portal/builder`, `/portal/settings`

**Admin:**
- `/admin/overview`, `/admin/tenants`, `/admin/health`

## Discovery Steps

After auditing the pages above, you MUST do the following:

1. **Read the routing configuration** — find the router files (e.g., `apps/site/src/router.tsx`, `apps/web/src/App.tsx`) to discover ALL routes
2. **Navigate to undiscovered routes** — any route not yet audited, go audit it
3. **Explore interactive elements** — click buttons, dropdowns, modals, tabs to find secondary pages
4. **Check authenticated flows** — after logging in, explore the full portal experience
5. **Look for dynamic content** — pages that load based on data (e.g., `/portal/agents/:id`, `/admin/tenants/:id`)

## Setup

1. Checkout the target repository
2. Install dependencies: `pnpm install`
3. Install Playwright browsers: `pnpm playwright install chromium`
4. Seed database if needed: `pnpm --filter @o11yfleet/worker db-seed` (or check for seed script)
5. Start the API worker:
   ```bash
   cd apps/worker && pnpm dev &
   ```
   Wait for "Ready on" message on port 8787
6. Start the site app:
   ```bash
   cd apps/site && pnpm dev &
   ```
   Wait for localhost:4000
7. Start the web app (if testing both):
   ```bash
   cd apps/web && pnpm dev &
   ```
   Wait for localhost:3000

## Run the Love Audit

Create and execute the audit script:

```bash
cat > /tmp/love-audit.mjs << 'EOJS'
import { chromium } from 'playwright';
import { mkdir, writeFile } from 'fs/promises';

const SITE_BASE = 'http://localhost:4000';
const WEB_BASE = 'http://localhost:3000';

const PAGES = [
  // Site app pages
  { name: 'site-home', base: SITE_BASE, path: '/' },
  { name: 'site-login', base: SITE_BASE, path: '/login' },
  { name: 'site-admin-login', base: SITE_BASE, path: '/admin-login' },
  { name: 'site-portal-overview', base: SITE_BASE, path: '/portal/overview' },
  { name: 'site-portal-agents', base: SITE_BASE, path: '/portal/agents' },
  { name: 'site-portal-configs', base: SITE_BASE, path: '/portal/configurations' },
  { name: 'site-portal-builder', base: SITE_BASE, path: '/portal/builder' },
  { name: 'site-admin-overview', base: SITE_BASE, path: '/admin/overview' },
  { name: 'site-admin-tenants', base: SITE_BASE, path: '/admin/tenants' },
  { name: 'site-admin-health', base: SITE_BASE, path: '/admin/health' },
  // Web app pages
  { name: 'web-home', base: WEB_BASE, path: '/' },
  { name: 'web-login', base: WEB_BASE, path: '/login' },
  { name: 'web-portal-overview', base: WEB_BASE, path: '/portal/overview' },
  { name: 'web-admin-overview', base: WEB_BASE, path: '/admin/overview' },
];

const results = [];
const browser = await chromium.launch();
const context = await browser.newContext({
  viewport: { width: 1440, height: 900 }
});

await mkdir('/tmp/love-audit', { recursive: true });

for (const pageDef of PAGES) {
  const page = await context.newPage();
  const url = `${pageDef.base}${pageDef.path}`;
  const slug = pageDef.name;
  
  console.log(`Auditing: ${slug} (${url})`);
  
  try {
    // Navigate and wait for network idle
    await page.goto(url, { waitUntil: 'networkidle', timeout: 30000 });
    
    // Capture screenshot
    await page.screenshot({ 
      path: `/tmp/love-audit/${slug}.png`, 
      fullPage: true 
    });
    
    // Capture ARIA snapshot
    const ariaSnapshot = await page.accessibility.snapshot();
    await writeFile(
      `/tmp/love-audit/${slug}-aria.yaml`, 
      JSON.stringify(ariaSnapshot, null, 2)
    );
    
    // Capture DOM dump (main content area)
    const domContent = await page.evaluate(() => {
      const main = document.querySelector('main') || document.body;
      return main.innerHTML;
    });
    await writeFile(`/tmp/love-audit/${slug}-dom.html`, domContent);
    
    // Run quick accessibility check (color contrast only)
    const a11yIssues = await page.evaluate(() => {
      const issues = [];
      // Check for missing alt text on images
      document.querySelectorAll('img').forEach(img => {
        if (!img.alt && !img.getAttribute('role')) {
          issues.push(`img without alt: ${img.src}`);
        }
      });
      // Check for buttons without accessible names
      document.querySelectorAll('button').forEach(btn => {
        if (!btn.textContent.trim() && !btn.getAttribute('aria-label')) {
          issues.push(`button without accessible name: ${btn.className}`);
        }
      });
      return issues;
    });
    
    results.push({
      page: slug,
      url,
      status: 'success',
      screenshot: `/tmp/love-audit/${slug}.png`,
      aria: `/tmp/love-audit/${slug}-aria.yaml`,
      dom: `/tmp/love-audit/${slug}-dom.html`,
      a11yIssues
    });
    
  } catch (e) {
    results.push({
      page: slug,
      url,
      status: 'error',
      error: e.message
    });
  }
  
  await page.close();
}

await browser.close();

// Write summary
await writeFile('/tmp/love-audit/results.json', JSON.stringify(results, null, 2));
console.log('Audit complete. Results written to /tmp/love-audit/results.json');
EOJS

cd /tmp && node love-audit.mjs 2>&1 | tee /tmp/love-audit-output.txt
```

## Analyze

1. Read `/tmp/love-audit/results.json` to see which pages were audited
2. **Read every screenshot** from `/tmp/love-audit/*.png`
3. **Read the ARIA snapshots** from `/tmp/love-audit/*-aria.yaml`
4. **Read the DOM dumps** from `/tmp/love-audit/*-dom.html`

### What to Look For

**Visual Issues:**
- Layout problems (overlapping elements, broken alignment)
- Missing or placeholder content (empty tables, blank areas)
- Inconsistent spacing, font sizes, visual weight
- Truncated text or overflow
- Missing loading indicators or empty states
- Unpolished or "broken" looking elements
- Empty state inconsistency — should have centered icon + title + helper text

**Accessibility Issues:**
- Missing labels on form inputs
- Buttons without text or aria-label
- Images without alt text
- Color contrast problems (especially in dark mode)
- Missing heading hierarchy

**UX Papercuts:**
- Confusing navigation or flow
- Counterintuitive interactions
- Missing feedback on actions
- Error messages that aren't helpful

## Known o11yfleet Patterns to Check

Based on common issues:
1. **text.secondary contrast** — dark mode secondary text may be hard to read
2. **Empty state consistency** — portal and admin pages should all have polished empty states
3. **Filter bar height** — if filters exist, all fields should be same height
4. **Button states** — disabled buttons should look disabled
5. **Loading states** — data-heavy pages should show loading skeletons

## Output Rules

- **Silence is better than noise.** Only file an issue for genuine paper cuts.
- Do NOT file for purely cosmetic nitpicks or subjective preferences.
- If you find issues, create **one** GitHub issue covering all pages.
- If all pages look good, call `noop`.

## Issue Format

```
## UX Love Audit Summary

**Repository:** [target_repo]
**Audit date:** [date]
**Pages audited:** [count]
**Overall quality:** [impression]

### Paper Cuts Found

| Page | Issue | Severity | Screenshot |
|------|-------|----------|-----------|
| [page] | [description] | [paper-cut/rough-edge/bug] | [file] |

### Accessibility Issues

| Page | Issue | WCAG | Element |
|------|-------|------|---------|
| [page] | [description] | [criterion] | [selector] |

### Visual Inconsistencies

- [Page A] vs [Page B] — [inconsistent pattern]

## Recommendations

- [ ] Prioritize critical papercuts
- [ ] Standardize empty states across pages
- [ ] Add loading skeletons to data-heavy pages
```