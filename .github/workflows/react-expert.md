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

{{#include .github/workflows/gh-aw-fragments/rigor.md}}

{{#include .github/workflows/gh-aw-fragments/previous-findings.md}}

Audit React and TypeScript code for anti-patterns and best practice violations.

**Target Repository**: ${{ inputs.target_repo }}
**File Filter**: ${{ inputs.file_filter }}

## Step 1: Understand the Project Before Auditing

Before reviewing any component files, read these files first:

1. `package.json` — identify React version, framework (Next.js/Vite/Remix/CRA), and whether
   `babel-plugin-react-compiler` or `@next/react-compiler` is present.
2. `tsconfig.json` — check `strict` mode, path aliases.
3. One or two existing components to understand the project's conventions, state libraries,
   styling approach (Tailwind, MUI, CSS modules), and data-fetching patterns.

**Record these findings before proceeding.** They change which rules apply.

### Framework Routing Table

| Detected Setup | Data Fetching Standard | Memoization Guidance |
|---|---|---|
| Next.js App Router | Async Server Components or Server Actions | React Compiler likely active — skip manual memo |
| Next.js Pages Router | `getServerSideProps` / `getStaticProps` or SWR/TanStack Query | Manual memo may still be appropriate |
| Remix / RR v7 | Loaders and Actions | Manual memo may still be appropriate |
| Vite / CRA SPA | TanStack Query, SWR, or custom hooks | Manual memo may still be appropriate |

---

## React Anti-Patterns

### 🔴 Critical — Correctness & Crashes

**1. Conditional or post-return hooks**
Hooks called inside `if` blocks, loops, ternaries, after an early `return`, inside `try/catch`,
or inside event handlers. Violates React's rules of hooks — causes ordering bugs and runtime errors.

**2. Component definitions inside other components**
```tsx
// ❌ Child is recreated on every render — resets all hooks, kills memoization
const Parent = () => {
  const Child = () => <div />;  // move this outside Parent
  return <Child />;
};
```
This silently resets all hook state inside Child on every render. It is one of the most common
hard-to-diagnose React bugs.

**3. Direct state mutation**
```tsx
state.items.push(item); setState(state); // ❌ mutating the same reference
```

**4. Missing cleanup for subscriptions, timers, or async operations**
```tsx
// ❌ Race condition — no AbortController, no cleanup
useEffect(() => {
  fetch(`/api/data/${id}`).then(r => r.json()).then(setData);
}, [id]);
```
Fix: `AbortController` + cleanup return, or replace with TanStack Query / SWR.

**5. Setting state during render (outside event handlers or effects)**
Causes an infinite render loop or at minimum extra renders.

**6. Unstable keys in lists**
- Missing `key` prop entirely
- `key={index}` when list items can be reordered or removed
- `key={Math.random()}` or any value that changes every render

---

### 🟠 High — Performance & Correctness

**7. Unnecessary `useEffect` — derive instead of synchronize**

If a value can be computed from props or existing state during render, computing it inline is
always correct and faster. `useEffect` for this causes a double render.

```tsx
// ❌ Unnecessary effect — causes extra render
const [filtered, setFiltered] = useState([]);
useEffect(() => {
  setFiltered(items.filter(i => i.active));
}, [items]);

// ✅ Derive during render
const filtered = items.filter(i => i.active);
```

Flag these patterns as unnecessary effects:
- Filtering/sorting/mapping state or props into new state
- Copying a prop into local state (`useState(props.value)`)
- Computing a string, count, or total from other state
- Syncing two pieces of React state that should be one

**8. `useEffect` with incorrect or missing dependency array**
- Missing declared variables used inside the effect (stale closures)
- Empty `[]` when the effect actually uses reactive values
- No dependency array at all (runs every render, almost always a bug)

**9. `onClick` (or other event handlers) on non-interactive elements**
`<div onClick>`, `<span onClick>`, `<Box onClick>` without `role="button"` and `tabIndex={0}`.
These are inaccessible: keyboard users cannot focus or activate them. Use `<Button>`,
`<IconButton>`, or `<ListItemButton>` instead.

**10. Inline function or object literals defeating memoized children**
```tsx
// ❌ New reference on every render — breaks React.memo on ChildComponent
<ChildComponent onAction={() => doThing(id)} style={{ margin: 8 }} />
```
Use `useCallback` / `useMemo` (or move the value outside the component if it doesn't close over
state). Exception: skip this if the React Compiler is detected (it handles it automatically).

**11. Empty/null/missing states rendered as blank space**
Conditional rendering for `data.length === 0`, `!results`, `isLoading` that returns `null` or
an empty `<div>` creates blank UI rectangles. Render a proper `<EmptyState />` or skeleton
component.

**12. Context value object/array created inline in the provider**
```tsx
// ❌ New object reference every render — every consumer re-renders
<MyContext.Provider value={{ user, logout }}>
```
Stabilize with `useMemo`, or split into separate contexts by update frequency.

**13. Prop drilling beyond 2–3 levels**
When the same prop passes through 3+ components that don't use it, factor it into Context,
Zustand, or another state solution.

**14. MUI barrel imports**
```tsx
// ❌ Prevents tree-shaking, bloats bundle
import { Button, Stack, Typography } from '@mui/material';

// ✅
import Button from '@mui/material/Button';
import Stack from '@mui/material/Stack';
```

---

### 🟡 Medium — Code Quality & Maintainability

**15. Hardcoded colors**
Hex/rgb/rgba in `sx` props or `style` objects. Use theme tokens (`'primary.main'`,
`'text.secondary'`) for consistent theming and dark mode support.

**16. Non-standard spacing values**
Arbitrary numeric `sx` values outside the project's approved spacing scale.
Approved: `0, 0.5, 1, 1.5, 2, 2.5, 3, 4, 6`.

**17. Non-approved Typography variants**
Approved: `h3, h5, h6, subtitle1, body1, body2, caption`.

**18. `useState` for values that don't affect rendering**
Timers, previous value refs, imperative handles — use `useRef` instead to avoid unnecessary
re-renders.

**19. God components**
Components >150 lines or with >6 props where concerns are mixed. Extract sub-components and
logic into custom hooks.

**20. `useEffect` calling external library init that doesn't depend on state**
Move module-level initialization outside the component entirely.

---

## TypeScript Anti-Patterns

### 🔴 Critical

**T1. `any` type usage**
Variables, function parameters, or return types typed as `any`. Replace with specific types,
`unknown` + narrowing, or generics.

**T2. Unsafe type assertions without validation**
`value as SomeType` without a type guard. Non-null assertions (`!`) without a documented
guarantee. These are silent runtime crash sources.

**T3. Missing discriminated unions for UI state**
```tsx
// ❌ These can be contradictory — both true/false simultaneously
const [isLoading, setIsLoading] = useState(false);
const [isError, setIsError] = useState(false);
const [data, setData] = useState(null);

// ✅ Impossible states become unrepresentable
type State = { status: 'loading' } | { status: 'error'; error: Error } | { status: 'success'; data: Data };
```

---

### 🟠 High

**T4. Missing null checks on optional chaining chains**
Cascading `?.?.?.` that silently swallows undefined values, hiding real bugs.

**T5. `Array<any>` instead of typed generics**
`useState<any[]>([])`, `useRef<any>()`, function parameters `fn(items: any[])`.

**T6. Untyped event handlers**
```tsx
// ❌
const handleChange = (e) => { ... }

// ✅
const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => { ... }
```

**T7. Props spreading untyped or overly broad objects**
`{...props}` where `props` is `any` or `object` — forwards unknown attributes to DOM elements,
causes React warnings and potential XSS vectors.

---

### 🟡 Medium

**T8. Underuse of utility types**
Manually reimplementing `Partial`, `Required`, `Pick`, `Omit`, `Record`, `ReturnType`.

**T9. JavaScript-style enums instead of union types**
```tsx
// ❌ Creates runtime overhead and bundle bloat
enum Status { Active, Inactive }

// ✅
type Status = 'active' | 'inactive';
```

**T10. Missing `readonly` on shared immutable data**
Arrays and objects passed into components for display should be `readonly` to prevent
accidental mutation.

---

## Issue Output Format

Create one consolidated issue with all findings, grouped by severity. Skip sections with no findings.

### Before Filing — Quality Gate

**Every finding must pass ALL of these:**
1. **Concrete evidence** — exact file path and line number
2. **Actionable** — a maintainer can fix it without re-investigating
3. **Not duplicate** — checked `previous-findings.json` for existing issues
4. **Worth human time** — not noise or trivial

**If no findings pass all four gates, call `noop`.**

### Issue Format

```
## React/TypeScript Code Audit Summary

**Repository:** [target_repo]
**Files audited:** [count]
**Issues found:** [count by severity]

### Critical Severity

#### 1. [Title]
**File:** [path:line]
**Problem:** [description]
**Fix:** [specific approach]

### High Priority

...

## Recommended Actions

- [ ] [Actionable fix for each critical issue]
```

If no significant React/TypeScript issues found, call `noop`.
