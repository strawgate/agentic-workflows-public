---
name: "Dev Loop Audit"
description: "Audit local dev setup time, loop time, and first-time environment setup from scratch"
on:
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
    title-prefix: "[dev-loop] "
    labels: [dev-experience, dx, automated]
    max: 1
    close-older-key: "[dev-loop]"
    close-older-issues: true
    expires: 14d
    target-repo: ${{ inputs.target_repo }}

timeout-minutes: 180
---

{{#include .github/workflows/gh-aw-fragments/rigor.md}}

{{#include .github/workflows/gh-aw-fragments/previous-findings.md}}

Audit the local development experience: setup time, dev loop speed, and first-time environment bootstrap.

**Target Repository**: ${{ inputs.target_repo }}

## Your Mission

You are evaluating the **developer experience** from scratch. Your goal is to answer:

1. **Setup Time** — How long does it take to go from `git clone` to a running dev environment?
2. **Loop Time** — How long from editing a file to seeing the change live?
3. **Reliability** — Does the setup work consistently? Are there race conditions or hidden dependencies?
4. **Clarity** — Are setup instructions clear? Can a new developer get started without asking questions?

**Be thorough and skeptical.** If something is slow, unclear, or fragile, it's a finding.

## Setup: Clone Fresh

Start with a completely fresh clone to simulate a new developer's experience:

```bash
# Create temp directory for audit
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

# Measure clone time
START=$(date +%s.%N)
git clone https://github.com/${{ inputs.target_repo }}.git
CLONE_TIME=$(echo "$(date +%s.%N) - $START" | bc)

# Measure install time
cd $(basename "${{ inputs.target_repo }}")
START=$(date +%s.%N)
pnpm install --frozen-lockfile 2>&1 | tail -5
INSTALL_TIME=$(echo "$(date +%s.%N) - $START" | bc)

echo "Clone time: ${CLONE_TIME}s"
echo "Install time: ${INSTALL_TIME}s"
```

## Audit 1: First-Time Setup

### Step 1: Read Setup Documentation

1. Read `README.md` — look for "Getting Started", "Development", "Setup" sections
2. Read `DEVELOPING.md` if it exists
3. Check for `justfile` or `Makefile` — what `just` or `make` targets exist?
4. Look for `.env.example` or `.env.template` files
5. Check for any `CONTRIBUTING.md` or `dev-docs/` directory

### Step 2: Execute Setup Commands

Run the documented setup steps and TIME EVERY COMMAND:

```bash
# Time each step
START=$(date +%s.%N)
just setup 2>&1 | tee /tmp/setup-output.txt
SETUP_TIME=$(echo "$(date +%s.%N) - $START" | bc)
echo "Total setup time: ${SETUP_TIME}s"

# Check for errors in output
if grep -i "error\|failed\|crash\|exception" /tmp/setup-output.txt; then
  echo "SETUP ERRORS DETECTED"
fi
```

### Step 3: Verify Services Start

```bash
# Time to start API worker
START=$(date +%s.%N)
pnpm --filter @o11yfleet/worker dev &
WORKER_PID=$!
sleep 30  # Wait for worker to potentially start
if kill -0 $WORKER_PID 2>/dev/null; then
  echo "Worker started"
else
  echo "Worker failed to start"
fi
WORKER_START_TIME=$(echo "$(date +%s.%N) - $START" | bc)

# Check if ports are listening
sleep 5
netstat -an 2>/dev/null | grep -E "8787|3000|4000" || ss -tlnp | grep -E "8787|3000|4000" || true
```

### Step 4: Start Frontend Apps

```bash
# Time to start web app
START=$(date +%s.%N)
pnpm --filter @o11yfleet/web dev &
WEB_PID=$!
sleep 30
if kill -0 $WEB_PID 2>/dev/null; then
  echo "Web app started"
else
  echo "Web app failed to start"
fi
WEB_START_TIME=$(echo "$(date +%s.%N) - $START" | bc)
```

### Step 5: Verify End-to-End Works

```bash
# Test that the app actually responds
curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/ || echo "FAILED"
curl -s -o /dev/null -w "%{http_code}" http://localhost:8787/healthz || echo "FAILED"

# Test that the API worker responds correctly
curl -s http://localhost:8787/healthz | head -c 200
```

## Audit 2: Dev Loop Time

### Hot Reload Detection

1. Make a trivial change to a file (e.g., add a comment to a .ts file)
2. Time how long until the change is reflected
3. Measure across multiple attempts to get average

```bash
# Find a file to modify
FILE=$(find apps/web/src -name "*.tsx" | head -1)
echo "Modifying: $FILE"

# Make a change
START=$(date +%s.%N)
echo "// test $(date +%s)" >> "$FILE"
sleep 5  # Give hot reload time to trigger

# Check if dev server detected the change
# (watch for output in the dev server logs)
LOOP_TIME=$(echo "$(date +%s.%N) - $START" | bc)
echo "Hot reload time: ${LOOP_TIME}s"

# Revert the change
git checkout "$FILE"
```

### Build Time Audit

```bash
# Time a production build
START=$(date +%s.%N)
pnpm --filter @o11yfleet/web build 2>&1 | tail -10
BUILD_TIME=$(echo "$(date +%s.%N) - $START" | bc)
echo "Build time: ${BUILD_TIME}s"
```

## Audit 3: Database & Migrations

```bash
# Check migration status
pnpm --filter @o11yfleet/worker db-migrations-status 2>&1 || true

# Time to run migrations
START=$(date +%s.%N)
pnpm --filter @o11yfleet/worker db-migrate 2>&1
MIGRATION_TIME=$(echo "$(date +%s.%N) - $START" | bc)
echo "Migration time: ${MIGRATION_TIME}s"

# Time to seed data (if applicable)
START=$(date +%s.%N)
pnpm --filter @o11yfleet/worker db-seed 2>&1 || true
SEED_TIME=$(echo "$(date +%s.%N) - $START" | bc)
echo "Seed time: ${SEED_TIME}s"
```

## Audit 4: Test Execution Time

```bash
# Time to run core tests
START=$(date +%s.%N)
pnpm --filter @o11yfleet/web test --run 2>&1 | tail -20
TEST_TIME=$(echo "$(date +%s.%N) - $START" | bc)
echo "Test time: ${TEST_TIME}s"
```

## Audit 5: Identify Friction Points

While performing the audits above, actively look for:

1. **Undocumented prerequisites** — things the setup requires but doesn't mention (e.g., "you need Docker running", "must have Python 3.11")
2. **Race conditions** — steps that must be done in order or things fail intermittently
3. **Missing error messages** — commands that fail silently or with cryptic errors
4. **Obsolete documentation** — README says one thing, reality is different
5. **Magic steps** — things that work but nobody knows why (hidden environment variables, etc.)
6. **Slow commands** — anything that takes more than 30s that could be parallelized or cached
7. **Inconsistent tooling** — some things use `just`, others use `npm`, others use direct `pnpm`
8. **Platform-specific issues** — works on Mac but not Linux, or vice versa

## Output Format

Create one issue summarizing all findings:

```
## Dev Loop Audit Summary

**Repository:** [target_repo]
**Audit date:** [date]

### Setup Time Breakdown

| Step | Time | Expected | Status |
|------|------|----------|--------|
| git clone | Xs | <30s | ✅/❌ |
| pnpm install | Xs | <60s | ✅/❌ |
| just setup | Xs | <120s | ✅/❌ |
| Worker start | Xs | <30s | ✅/❌ |
| Web app start | Xs | <30s | ✅/❌ |

### Dev Loop Performance

| Metric | Value | Target | Status |
|--------|-------|--------|--------|
| Hot reload | Xs | <3s | ✅/❌ |
| Full build | Xs | <120s | ✅/❌ |
| Test suite | Xs | <60s | ✅/❌ |
| Migrations | Xs | <10s | ✅/❌ |

### Critical Issues

#### 1. [Title]
**Severity:** [critical/high/medium]
**Finding:** [what you observed]
**Impact:** [developer productivity impact]
**Recommendation:** [specific fix]

... (more issues)

### Friction Points

- [ ] [Specific friction point with recommendation]

### Overall DX Score

Rate the overall developer experience: [1-10]

## Recommendations

Priority fixes:
1. [Most impactful change]
2. [Second most impactful]
3. [Third most impactful]
```

If the dev experience is excellent with no significant issues, call `noop`.