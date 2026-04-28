---
name: "Performance Profiler"
description: "Identify hot paths, benchmark code, and propose measurable performance improvements"
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
    title-prefix: "[performance] "
    labels: [performance, automated]
    max: 1
    close-older-key: "[performance]"
    close-older-issues: false
    expires: 7d
    target-repo: ${{ inputs.target_repo }}

timeout-minutes: 90
---

Identify performance hot paths and propose measurable improvements.

**Target Repository**: ${{ inputs.target_repo }}

**The bar is high: produce measurable profiling data before filing.** Most runs should end with `noop`.

## Data Gathering

1. **Detect language and build system**
   - Check for `go.mod`, `package.json`, `pyproject.toml`, `Cargo.toml`, etc.
   - Find test/benchmark commands from README, Makefile, CI config

2. **Look for existing benchmarks**
   - Go: `func Benchmark` in `*_test.go` files
   - Rust: `#[bench]` or criterion benchmarks
   - Node: benchmark scripts in package.json
   - Python: pytest-benchmark

3. **Identify likely hot paths**
   - Functions called frequently from entry points
   - Loops over large data
   - Repeated I/O, expensive string operations
   - Recent changes to performance-sensitive areas

## Profiling

Generate concrete data — don't speculate.

- **Rust**: `cargo bench` with criterion
- **Go**: `go test -bench=. -benchmem`
- **Node**: `perf_hooks` or `--prof`
- **Python**: `cProfile`, `timeit`, `pytest-benchmark`

Always capture **baseline numbers** before any change.

## Optimization

1. Identify single most impactful optimization
2. Implement smallest safe change
3. Re-run benchmark for **after** numbers
4. Verify tests still pass

## Data Integrity Check

Before filing:
- **Before** and **after** benchmarks must be **different**
- Same benchmark command must be used
- If benchmark didn't actually measure changed code, don't file

## Issue Format

```
## Performance Optimization Report

**Repository:** [target]

### Hot Path Identified
[Function/file and why it's hot]

### Benchmark Evidence
**Before:** [numbers]
**After:** [numbers]
**Improvement:** [% or absolute]

### Recommended Actions
- [ ] Implement [optimization]
```

If no measurable optimization opportunity found, call `noop`.
