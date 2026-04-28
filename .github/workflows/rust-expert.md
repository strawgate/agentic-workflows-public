---
name: "Rust Expert"
description: "Audit Rust code for anti-patterns, unsafe usage, and best practice violations"
on:
  schedule:
    - cron: '0 15 * * 5'  # Fridays 3PM UTC
  workflow_dispatch:
    inputs:
      target_repo:
        description: 'Target repository (owner/repo)'
        required: false
        default: 'strawgate/agentic-workflows-playground'
        type: string
      file_filter:
        description: 'Glob pattern for Rust files (e.g., "crates/**/src/**/*.rs")'
        required: false
        default: '**/*.rs'
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
    title-prefix: "[rust-expert] "
    labels: [rust, code-quality, automated]
    max: 1
    close-older-key: "[rust-expert]"
    close-older-issues: true
    expires: 14d
    target-repo: ${{ inputs.target_repo }}

timeout-minutes: 90
---

Audit Rust code for language-specific anti-patterns, unsafe usage, and best practice violations.

**Target Repository**: ${{ inputs.target_repo }}
**File Filter**: ${{ inputs.file_filter }}

## Your Task

1. Explore the repository structure to understand the Rust project layout
2. Identify Cargo.toml files to understand crate structure
3. Focus on areas most likely to have Rust-specific issues

## Rust Anti-Patterns to Look For

### Critical (Safety & Correctness)

1. **Unsafe Blocks Without SAFETY Comments**
   - Every `unsafe` block MUST have a `// SAFETY:` comment immediately above
   - The comment must name the specific invariant being relied upon
   - Generic comments like "this is safe" or "bounds checked" are insufficient

2. **Unsafe in `#![forbid(unsafe_code)]` Crates**
   - Check for crates with `forbid(unsafe_code)` in lib.rs
   - Any unsafe in such crates is a compile error

3. **Missing Error Handling**
   - `unwrap()` on Result/Option in production code
   - `expect()` without meaningful messages
   - `.ok()` or `.unwrap()` swallowing errors silently

4. **Thread Safety Violations**
   - `Mutex` protected data accessed without lock
   - `Send`/`Sync` implemented incorrectly
   - Data races in concurrent code

### High Priority

5. **Clone on Hot Paths**
   - Excessive `.clone()` calls in frequently-executed code
   - Consider `Arc`, `Rc`, or reference patterns instead

6. **Allocation in Loops**
   - `String::new()` or `Vec::new()` inside loops
   - String concatenation with `+` in loops (use `format!` with capacity or `write!`)

7. **Wrong Error Types**
   - Using `String` or `Box<dyn Error>` where typed errors expected
   - Propagating errors without context (`?` without `map_err`)

8. **Iterator Anti-Patterns**
   - `.collect::<Vec<_>>()` when iteration suffices
   - `.iter().map().collect()` when `.map().collect()` suffices
   - Collecting to Vec then iterating when direct iteration works

### Medium Priority

9. **Clippy Lint Violations**
   - `redundant_clone` - cloning data that's already owned
   - `explicit_iter_loop` - implicit iterators preferred
   - `needless_pass_by_ref` - unnecessary references
   - `single_match` vs `if let` - readability
   - `boxed_local` - boxing stack-allocated values

10. **Lifetime Issues**
    - `'static` lifetime on references when shorter lifetime expected
    - Lifetime elision rules misunderstood
    - Borrows held across yield points

11. **Async/Await Issues**
    - Blocking in async context (`.block_on` inside async fn)
    - Shared mutable state without proper synchronization
    - `Unpin` and `Future` implementation issues

12. **Macro Issues**
    - `$expr:block` when `$expr` suffices
    - Excessive macro use when functions would suffice
    - `format!` in `panic!` when `panic_any` would work

### Low Priority

13. **Documentation**
    - Missing doc comments on public APIs
    - `#[allow(dead_code)]` suppressing legitimate warnings
    - Undocumented `pub` items

14. **Test Quality**
    - Tests without assertions
    - `#[test]` functions that always pass
    - Missing proptest/property-based tests for complex code

## Issue Format

Create one consolidated issue with all findings:

```
## Rust Code Audit Summary

**Repository:** [target_repo]
**Files audited:** [count]
**Issues found:** [count by severity]

### Critical Severity

#### 1. [Title]
**File:** [path:line]
**Problem:** [description]
**Fix:** [suggested approach]

### High Priority

...

## Recommended Actions

- [ ] [Actionable fix for each critical issue]
```

If no significant Rust-specific issues found, call `noop`.
