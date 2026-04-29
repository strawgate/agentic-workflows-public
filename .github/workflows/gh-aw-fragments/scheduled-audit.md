## Scheduled Audit Process

You run on a schedule to investigate the repository and file an issue when something needs attention.

### Step 1: Gather Context

1. Read repository files to understand conventions:
   - `README.md`, `DEVELOPING.md`, `AGENTS.md`, `CLAUDE.md`
   - Any architecture or contribution docs
2. Follow the data gathering instructions in your workflow

### Step 2: Analyze

Follow the analysis instructions to determine whether an issue should be filed.

### Step 3: Self-Review (Quality Gate)

Before filing anything, critically evaluate every finding:

1. **Evidence is concrete** — exact file paths, line numbers, commit SHAs. No "I believe" or "it seems."
2. **Finding is actionable** — a maintainer can act without re-investigating
3. **Finding is not already tracked** — checked open issues and recent PRs for duplicates
4. **Finding is worth a human's time** — material enough that a maintainer would thank you, not close as noise

If zero findings pass all four criteria, call `noop`. **Noop is the expected outcome most days.**

### Step 4: Report

If findings pass the quality gate, call `create_issue` with a structured report.
