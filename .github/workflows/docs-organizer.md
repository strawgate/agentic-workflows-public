---
name: "Docs Organizer"
description: "Audit and restructure repository documentation to follow standardized patterns"
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
    title-prefix: "[docs-organizer] "
    labels: [documentation, automated]
    max: 1
    close-older-key: "[docs-organizer]"
    close-older-issues: true
    expires: 7d
    target-repo: ${{ inputs.target_repo }}

timeout-minutes: 60
---

Audit and restructure this repository's documentation to follow a standardized pattern. Each file has a specific audience and purpose — don't mix concerns.

**Target Repository**: ${{ inputs.target_repo }}

## Standard documentation structure

### Root level

| File | Audience | Purpose | Content |
|------|----------|---------|---------|
| `README.md` | Users | What this project is, how to install, how to run | User-facing only. No internal architecture. Links to docs for details. |
| `DEVELOPING.md` | Developers | How to build, test, contribute | Build commands, test commands, crate/package structure, how to add features. |
| `CODE_STYLE.md` | Code reviewers (Coderabbit) | Subjective style preferences | Naming conventions, comment style, PR conventions. NOT enforced lints — those go in config files. |
| `AGENTS.md` | AI agents (Claude, Copilot) | Routing table + rules | Short. Points to other docs. Lists crate/package-specific rules. |
| `CLAUDE.md` | Claude Code | Symlink → AGENTS.md | `ln -s AGENTS.md CLAUDE.md` |
| `.github/copilot-instructions.md` | Copilot | Points to AGENTS.md | Short file: "Read AGENTS.md for full instructions." |

### Per-package/crate level (as needed)

| File | Purpose |
|------|---------|
| `README.md` | What this package does, its role in the system |
| `AGENTS.md` | Package-specific rules for AI agents (e.g., "this crate is no_std", "every public function needs a test") |
| `CLAUDE.md` | Symlink → AGENTS.md |
| `CODE_STYLE.md` | Package-specific style preferences for reviewers |

### Documentation directories

| Directory | Purpose |
|-----------|---------|
| `docs/` or `dev-docs/` | Architecture docs, design decisions, ADRs |
| `docs/references/` | Library/API-specific guides |
| `docs/research/` | Research results that informed decisions |

## Key principles

1. **AGENTS.md is a routing table, not a knowledge dump.** It says "read these files" and "here are the rules" — short enough that an agent actually reads all of it. No more than ~100 lines.

2. **CODE_STYLE.md is for subjective preferences only.** Things a code reviewer should enforce but that can't be linted. Naming patterns, comment expectations, architectural preferences. Enforced rules go in config files (Cargo.toml `[lints]`, .eslintrc, rustfmt.toml, etc.).

3. **CLAUDE.md is always a symlink to AGENTS.md.** One source of truth for all AI agents.

4. **Per-package AGENTS.md captures rules specific to that package.** An agent working in a package sees its rules automatically via CLAUDE.md.

5. **README.md is user-facing.** No internal architecture details. A user who just wants to install and run shouldn't need to read about crate boundaries or verification strategies.

6. **DEVELOPING.md is developer-facing.** Everything a new contributor needs: how to build, test, run benchmarks, add features, understand the crate structure.

## Instructions

1. Read the current repository structure and existing documentation files (README.md, DEVELOPING.md, AGENTS.md, CLAUDE.md, .github/copilot-instructions.md, any docs/ directory).

2. Identify what exists and what's missing or misplaced.

3. Propose a plan for restructuring. Ask the user before making changes.

4. When restructuring:
   - Don't delete content — move it to the right file
   - Create symlinks for CLAUDE.md → AGENTS.md
   - Keep AGENTS.md lean (routing table)
   - Separate user content (README) from developer content (DEVELOPING) from style (CODE_STYLE) from agent instructions (AGENTS)
   - Create per-package docs only where the package has specific rules worth documenting

5. After restructuring, verify:
   - CLAUDE.md is a symlink to AGENTS.md at each level
   - .github/copilot-instructions.md points to AGENTS.md
   - No file mixes audiences (user + developer + agent content in one file)
   - AGENTS.md is under 100 lines

## Issue Format

```
# Documentation Organization Report

## Current State
- [Files identified]
- [Missing files]
- [Files with mixed audiences]

## Proposed Restructuring Plan
1. [First action]
2. [Second action]
...

## Verification Checklist
- [ ] CLAUDE.md symlinks verified
- [ ] No mixed-audience files
- [ ] AGENTS.md under 100 lines
```

Call `create_issue` with the proposed plan, or `noop` if docs are already properly organized.
