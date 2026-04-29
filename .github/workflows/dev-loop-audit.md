---
name: "Dev Loop Audit"
description: "Audit whether an agent (or new developer) can successfully set up and run a project from scratch by following documented instructions"
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

Audit whether an agent (or new developer) can successfully set up a project from scratch by following the project's own documentation.

**Target Repository**: ${{ inputs.target_repo }}

## Your Mission

You are testing whether the repository is **agent-friendly** — can you, using only the documented instructions and the available tools (git, npm/pnpm/yarn, docker, make, etc.), successfully:

1. Clone the repo
2. Install dependencies
3. Start the application
4. Run the tests

If you encounter friction, undocumented steps, or broken instructions, document it as a finding.

**This is a meta-audit** — you're not testing the app's features, you're testing whether the setup instructions actually work.

## Setup: Create Fresh Clone

```bash
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"
git clone https://github.com/${{ inputs.target_repo }}.git
cd $(basename "${{ inputs.target_repo }}")
pwd
```

## Phase 1: Discover the Project

Before running any commands, understand what this project is:

1. Read `README.md` — what does this project do?
2. Look at the root directory structure — what kind of project is this?
3. Check for setup files: `package.json`, `Cargo.toml`, `go.mod`, `Makefile`, `justfile`, `docker-compose.yml`, `Dockerfile`, `pyproject.toml`, etc.
4. Find the documented setup steps — look for "Getting Started", "Development", "Setup", "Install" sections

**Record:**
- What package manager is used (npm/pnpm/yarn/bun/gem/cargo/go/etc)?
- What is the main language/framework?
- Are there any special prerequisites (Docker, specific OS, external services)?
- What commands are documented for setup?

## Phase 2: Follow the Instructions

**Execute the documented setup steps EXACTLY as written.** Do not improvise or skip steps. If a step doesn't work, that's a finding.

### Step 1: Install Dependencies

```bash
# Identify and run the correct install command
# Options (in order of likelihood):
pnpm install        # if pnpm-lock.yaml or pnpm-workspace.yaml exists
npm install         # if package-lock.json exists
yarn install       # if yarn.lock exists
bun install         # if bun.lockb exists
make dependencies   # if Makefile with install target
make setup          # if Makefile with setup target
just setup          # if justfile exists
docker compose up   # if docker-compose.yml exists

# Record: did it succeed? How long did it take?
```

### Step 2: Build/Compile (if applicable)

```bash
# Options:
pnpm build
npm run build
make build
just build
cargo build
go build ./...

# Record: did it succeed? How long?
```

### Step 3: Start the Application

```bash
# Options (check README for the exact command):
pnpm dev
npm run dev
make dev
just dev
docker compose up
just start
cargo run

# If it starts a server, verify it's running:
sleep 10
curl -s -o /dev/null -w "%{http_code}" http://localhost:3000 || \
curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 || \
curl -s -o /dev/null -w "%{http_code}" http://localhost:8000 || \
echo "Could not detect running server"
```

### Step 4: Run Tests

```bash
# Options:
pnpm test
npm test
make test
just test
cargo test
go test ./...
pytest

# Record: did tests pass? How long did they take?
```

## Phase 3: Identify Friction

As you execute the steps above, actively look for:

### Documentation Issues
- **Missing steps** — something required but not documented
- **Outdated docs** — README says X but reality is Y
- **Wrong commands** — documented command doesn't exist or does different thing
- **Assumed context** — "just do X" where X requires prior setup

### Tooling Issues
- **Wrong package manager** — docs say npm but project uses pnpm
- **Version mismatches** — requires Node 18 but project uses Node 20 features
- **Platform-specific** — works on Mac/Linux but not described as such
- **Magic commands** — things that work but aren't explained

### Environment Issues
- **Missing env vars** — requires `.env` file with secrets/API keys not documented
- **External dependencies** — needs Docker, database, Redis, etc. not mentioned
- **Network requirements** — can't work offline
- **Race conditions** — steps must be done in exact order

### Reliability Issues
- **Flaky setup** — works sometimes, fails others
- **Slow steps** — anything taking >2min that could be faster
- **No error handling** — failures give no useful information

## Output Format

```
## Dev Loop Audit Summary

**Repository:** [target_repo]
**Audit date:** [date]

### Setup Outcome

| Phase | Status | Duration |
|-------|--------|---------|
| Clone | ✅/❌ | Xs |
| Install deps | ✅/❌ | Xs |
| Build | ✅/❌ | Xs |
| Start app | ✅/❌ | Xs |
| Run tests | ✅/❌ | Xs |

### Findings

#### Critical (Blocks Setup)

**1. [Title]**
- **What:** [specific problem]
- **Doc says:** [what README says]
- **Reality:** [what actually happens]
- **Fix:** [how to fix the docs or the setup]

#### High (Significant Friction)

...

#### Medium (Minor Issues)

...

### Friction Points

1. [ ] [Issue with recommendation]

### Is This Repo Agent-Friendly?

Rate from 1-10: [score]

**Reasoning:** [why you gave this score]

## Recommendations

1. [Most impactful fix]
2. [Second most impactful]
3. [Third most impactful]
```

If setup worked flawlessly with no friction, call `noop`.