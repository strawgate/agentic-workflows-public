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
2. Identify Cargo.toml files to understand crate structure and dependencies
3. Determine whether each crate is a library or binary — error handling standards differ
4. Focus on areas most likely to have Rust-specific issues

## Rust Anti-Patterns to Look For

### Critical (Safety & Correctness)

1. **Unsafe Blocks Without SAFETY Comments**
   - Every `unsafe` block MUST have a `// SAFETY:` comment immediately above
   - The comment must name the specific invariant being upheld
   - Generic comments like "this is safe" or "bounds checked" are insufficient
   - Every `unsafe fn` must have a `# Safety` rustdoc section

2. **Missing or Incorrect Error Handling**
   - `unwrap()` or `expect()` on `Result`/`Option` in non-test, non-prototype code
   - `.ok()` silently discarding errors without acknowledgment
   - `panic!` used for recoverable errors (I/O, parsing, network, bad input)
   - Library crates returning `Box<dyn Error>` from public APIs — callers cannot match on it
   - `String` used as an error type

3. **Thread Safety Violations**
   - `Rc<T>` or `RefCell<T>` used across thread boundaries
   - `unsafe impl Send` / `unsafe impl Sync` without a documented safety argument
   - `std::sync::Mutex` guard held across an `.await` point — causes executor deadlock
   - Blocking calls (`std::thread::sleep`, synchronous I/O) inside `async fn`

4. **Unsound Unsafe Patterns**
   - Raw pointer arithmetic where slice indexing or iterators would work
   - Transmuting between types without a proof of validity
   - `unsafe` used solely to bypass a borrow-checker complaint that restructuring would fix

### High Priority

5. **Ownership and Borrowing Anti-Patterns**
   - `fn foo(s: &String)` — should be `fn foo(s: &str)`
   - `fn foo(v: &Vec<T>)` — should be `fn foo(v: &[T])`
   - `fn foo(p: &PathBuf)` — should be `fn foo(p: &Path)`
   - `.clone()` on large heap-allocated data to satisfy the borrow checker when restructuring would avoid it
   - `Rc<RefCell<T>>` or `Arc<Mutex<T>>` as default design tools when ownership restructuring is possible

6. **Error Type Design**
   - Library crates not using `thiserror` for structured, matchable error types
   - Application binaries not using `anyhow` for ergonomic context-rich errors
   - One mega error enum for the whole crate instead of per-module error types
   - Missing `# Errors` rustdoc sections on public fallible functions

7. **Stringly-Typed and Loosely-Typed APIs**
   - `String` used for domain identifiers, units, or states that should be typed enums or newtypes
   - `bool` parameters that make call sites unreadable (e.g., `fn process(reverse: bool)` — use an enum)
   - `u64`/`u32` used interchangeably for semantically distinct identifiers without newtypes

8. **Iterator and Allocation Anti-Patterns**
   - `.collect::<Vec<_>>()` immediately followed by `.iter()` — chain iterators directly
   - `String::new()` or `Vec::new()` inside loops without `with_capacity`
   - Collecting to `Vec` when `impl Iterator` return type would avoid allocation
   - String concatenation with `+` in loops — use `write!` into a `String` with capacity

### Medium Priority

9. **Pattern Matching Underuse**
   - `if opt.is_some() { opt.unwrap() }` — use `if let Some(x) = opt`
   - `if res.is_ok() { res.unwrap() }` — use `if let Ok(x) = res`
   - Catch-all `_ =>` match arms on enums you control that hide unhandled new variants
   - Verbose `if`/`else` chains over enums that should be `match`

10. **Async/Concurrency Issues**
    - `.block_on(...)` inside an `async fn`
    - `std::sync::Mutex` used in async code without understanding executor-blocking implications
    - Unbounded `tokio::spawn` without backpressure
    - Missing `Send` bounds on async traits used in multi-threaded runtimes

11. **Clippy Lint Violations**
    - `redundant_clone` — cloning data that's already owned
    - `needless_pass_by_ref` — unnecessary reference arguments
    - `single_match` — use `if let` instead
    - `boxed_local` — boxing stack-allocated values unnecessarily
    - `#[allow(...)]` attributes without a comment explaining why the lint is suppressed

12. **Lifetime Misuse**
    - `'static` lifetime on references when a shorter lifetime is correct
    - Borrows held across yield points in async code
    - Unnecessary explicit lifetimes that the compiler could elide

### Low Priority

13. **Documentation Gaps**
    - Missing `///` doc comments on public functions, structs, enums, and traits
    - Missing `# Errors` section on public fallible functions
    - Missing `# Panics` section on functions that can panic
    - Doc examples that don't compile (`cargo test --doc` would fail)
    - `#[allow(dead_code)]` suppressing legitimate warnings without explanation

14. **Test Quality**
    - Tests without meaningful assertions
    - No property-based tests (`proptest`/`quickcheck`) for parsers, codecs, or state machines
    - Missing regression tests for fixed bugs
    - Tests that test implementation details rather than behavior

## Issue Format

Create one consolidated issue with all findings:
Rust Code Audit Summary
Repository: [target_repo]
Files audited: [count]
Crates analyzed: [list library vs binary crates]
Issues found: [count by severity]

Critical Severity
1. [Title]
File: [path:line]
Problem: [description]
Fix: [suggested approach]

High Priority
...

Recommended Actions
[Actionable fix for each critical issue]

text

If no significant Rust-specific issues found, call `noop`.