# Agentic Workflows (Private)

Agentic workflows for auditing **private repositories**. These workflows use paid GitHub Actions minutes.

For public repositories, use the public version: [strawgate/agentic-workflows](https://github.com/strawgate/agentic-workflows)

## Available Workflows

See `.github/workflows/*.md` for workflow source files. Compiled versions are in `*.lock.yml`.

### Code Quality
- **architecture-guardian**: Structural violations (oversized files, long functions)
- **bug-hunter**: Reproducible bug detection
- **code-complexity-detector**: Complex code detection
- **code-duplication-detector**: Duplicate code detection
- **code-quality-audit**: General code quality issues
- **breaking-change-detector**: Undocumented breaking changes
- **duplicate-issue-detector**: Find duplicate issues
- **flaky-test-investigator**: Investigate flaky tests
- **refactor-opportunist**: Find refactoring opportunities
- **rust-expert**: Rust-specific anti-patterns
- **react-expert**: React/TypeScript anti-patterns
- **test-coverage-detector**: Find under-tested code

### Documentation
- **docs-organizer**: Enforce docs structure
- **docs-patrol**: Detect documentation drift
- **text-auditor**: Find typos and unclear text
- **newbie-contributor-patrol**: Review docs from new contributor perspective

### Development
- **dev-loop-audit**: Verify setup instructions work
- **performance-profiler**: Benchmark hot paths

### Security
- **malicious-code-scan**: Scan for suspicious code patterns

### UX
- **playwright-smoke-test**: UI smoke tests
- **playwright-a11y-audit**: Accessibility audit
- **playwright-love-audit**: Comprehensive UX audit

## Usage

All workflows accept a `target_repo` input to specify which repository to audit.

```bash
gh workflow run "workflow-name" --repo strawgate/agentic-workflows-private \
  -f target_repo=owner/private-repo
```

## Setup

Requires a GitHub App with appropriate permissions installed on target repositories.

See [agentic-workflows](https://github.com/strawgate/agentic-workflows) for full documentation.
