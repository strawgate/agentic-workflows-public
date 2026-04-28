---
name: "React/TypeScript Expert"
description: "Audit React and TypeScript code for anti-patterns and framework violations"
on:
  schedule:
    - cron: '0 16 * * 5'  # Fridays 4PM UTC
  workflow_dispatch:
    inputs:
      target_repo:
        description: 'Target repository (owner/repo)'
        required: false
        default: 'strawgate/agentic-workflows-playground'
        type: string
      file_filter:
        description: 'Glob pattern for TypeScript/React files'
        required: false
        default: '**/*.{ts,tsx}'
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
    title-prefix: "[react-expert] "
    labels: [typescript, react, code-quality, automated]
    max: 1
    close-older-key: "[react-expert]"
    close-older-issues: true
    expires: 14d
    target-repo: ${{ inputs.target_repo }}

timeout-minutes: 90
---

Audit React and TypeScript code for framework-specific anti-patterns and best practice violations.

**Target Repository**: ${{ inputs.target_repo }}
**File Filter**: ${{ inputs.file_filter }}

## Your Task

1. Explore the repository structure to understand the React/TypeScript project layout
2. Identify package.json to understand framework versions and dependencies
3. Focus on areas most likely to have React/TypeScript-specific issues

## React Anti-Patterns to Look For

### Critical (Performance & Correctness)

1. **Missing Key Props in Lists**
   - Map functions without `key` prop
   - Using index as key when items can be reordered
   - Keys that aren't stable across renders

2. **Inline Function Definitions in JSX**
   - `<button onClick={() => handleClick()}>` in render
   - Creates new function instance on every render
   - Extract to useCallback or define outside component

3. **Props Spreading Without Typing**
   - `{...props}` spreading untyped props
   - Spreading known props that shouldn't be forwarded
   - Missing prop restrictions

4. **useEffect Dependencies**
   - Missing dependencies in useEffect deps array
   - Stale closure issues
   - useEffect running on every render

### High Priority

5. **State Updates from Props**
   - Copying prop to local state without synchronization
   - `useState(initialValue)` where initialValue comes from props

6. **Context Misuse**
   - Creating new objects/arrays in render for context value
   - Context provider value changes on every render
   - Not splitting context by update frequency

7. **Component Composition Issues**
   - Props drilling more than 2-3 levels
   - Not using compound components when appropriate
   - Wrapper components that just pass through children

8. **Side Effects in Render**
   - API calls in render body
   - State updates in render
   - Navigation in render

## TypeScript Anti-Patterns

### Critical

9. **any Type Usage**
   - Variables typed as `any`
   - Function return types as `any`
   - Object without interface/type

10. **Type Assertions Without Validation**
    - `value as SomeType` without validation
    - Non-null assertions (`!`) without guarantees

11. **Structural Typing Abuse**
    - Duck typing causing runtime errors
    - Missing discriminated unions
    - Overly broad types hiding bugs

### High Priority

12. **Missing Null Checks**
    - Accessing properties without null checks
    - Optional chaining abuse (`?.?.?`)
    - Defensive programming not practiced

13. **Generics Misuse**
    - `Array<any>` instead of proper generic type
    - Overly complex generic constraints
    - Type inference defeat by casting

14. **readonly Inconsistency**
    - Mutable arrays/objects passed to functions expecting readonly
    - Missing `readonly` modifier on shared data
    - Inconsistent immutability patterns

15. **Enum Usage**
    - Using JavaScript enums instead of TypeScript const enums
    - String enums vs union types
    - Runtime enum values causing issues

### Medium Priority

16. **Utility Types Underuse**
    - Not using `Partial`, `Required`, `Pick`, `Omit`
    - Manually reimplementing utility type logic

17. **Decorator Confusion**
    - Incorrect decorator syntax
    - Experimental decorators without proper config

18. **Namespace vs Module**
    - Using `namespace` instead of ES modules
    - Import/export confusion

## Issue Format

Create one consolidated issue with all findings:

```
## React/TypeScript Code Audit Summary

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

If no significant React/TypeScript issues found, call `noop`.
